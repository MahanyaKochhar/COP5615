import gleam/bit_array
import gleam/crypto
import gleam/erlang/process
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order.{Eq, Gt, Lt}
import gleam/otp/actor
import gleam/result
import prng/random

const call_milliseconds = 50_000

const joining_gap_milliseconds = 5000

const requests_gap_milliseconds = 1000

type Node {
  Node(id: BitArray, subject: process.Subject(Message))
}

type Config {
  Config(counter: Int, max: Int)
}

fn generate_waiting_period() -> Int {
  let generator = random.int(5, 15)
  let period = random.random_sample(generator)
  period * 1000
}

pub fn add_power_of_2(id: BitArray, power: Int, m: Int) -> BitArray {
  let num_bytes = m / 8
  let offset = int.bitwise_shift_left(1, power)

  extract_and_add(id, 0, num_bytes, offset, [])
}

fn extract_and_add(
  id: BitArray,
  index: Int,
  total: Int,
  carry: Int,
  acc: List(Int),
) -> BitArray {
  case index >= total {
    True -> {
      // Convert accumulated list back to BitArray
      build_byte_array(acc, <<>>)
    }
    False -> {
      let pos = total - 1 - index
      // Read from right to left
      let byte = read_byte_at(id, pos)
      let sum = byte + carry

      extract_and_add(id, index + 1, total, sum / 256, [sum % 256, ..acc])
    }
  }
}

fn read_byte_at(bits: BitArray, index: Int) -> Int {
  case bit_array.slice(bits, index, 1) {
    Ok(<<b:int-size(8)>>) -> b
    // Specify 8 bits (1 byte)
    _ -> 0
  }
}

fn build_byte_array(bytes: List(Int), acc: BitArray) -> BitArray {
  case bytes {
    [] -> acc
    [b, ..rest] -> build_byte_array(rest, <<acc:bits, b:int-size(8)>>)
    // Specify size
  }
}

pub fn is_between_exclusive_inclusive(
  id: BitArray,
  start: BitArray,
  end: BitArray,
) -> Bool {
  case bit_array.compare(start, end) {
    Lt -> {
      bit_array.compare(id, start) == Gt && bit_array.compare(id, end) != Gt
    }
    Gt -> {
      bit_array.compare(id, start) == Gt || bit_array.compare(id, end) != Gt
    }
    Eq -> True
  }
}

pub fn is_between_exclusive_exclusive(
  id: BitArray,
  start: BitArray,
  end: BitArray,
) -> Bool {
  case bit_array.compare(start, end) {
    Lt -> {
      bit_array.compare(id, start) == Gt && bit_array.compare(id, end) == Lt
    }
    Gt -> {
      bit_array.compare(id, start) == Gt || bit_array.compare(id, end) == Lt
    }
    Eq -> id != start
    // or False if full circle should exclude everything
  }
}

fn generate_simple_ip(node: Int) -> String {
  "ip-address" <> "." <> int.to_string(node)
}

fn generate_lookup_id() -> BitArray {
  let generator = random.int(20, 300)
  let node_val = random.random_sample(generator)
  let ip = generate_simple_ip(node_val)
  let id = generate_identifier(ip)
  id
}

fn generate_identifier(str: String) -> BitArray {
  let digest = crypto.hash(crypto.Sha1, bit_array.from_string(str))
}

fn generate_base_finger_list(m: Int) -> List(Option(Node)) {
  list.range(1, m)
  |> list.map(fn(_idx) { None })
}

fn initialize_network(
  id: BitArray,
  m: Int,
  requests: Int,
  coordinator_subject: process.Subject(CoordinatorMessage),
) {
  let finger_list = generate_base_finger_list(m)
  let assert Ok(actor) =
    actor.new(#(id, None, None, finger_list, Config(0, m)))
    |> actor.on_message(handle_message)
    |> actor.start
  let subject = actor.data
  actor.send(subject, Create(subject))
  let stabilization_period = generate_waiting_period()
  let finger_fix_period = generate_waiting_period()

  process.send_after(
    coordinator_subject,
    requests_gap_milliseconds,
    ReceiveRequest(coordinator_subject, generate_lookup_id(), subject, requests),
  )
  process.send_after(subject, stabilization_period, Stabilize(subject))
  process.send_after(subject, finger_fix_period, FixFingers(subject))
  subject
}

fn termination_condition(
  coordinator_subject: process.Subject(CoordinatorMessage),
  nodes: Int,
) {
  let cnt = process.call(coordinator_subject, call_milliseconds, GetStatus)
  case cnt == nodes {
    True -> Nil
    False -> termination_condition(coordinator_subject, nodes)
  }
}

pub fn start_simulation(nodes: Int, requests: Int) -> Nil {
  io.println("Start simulation.")

  let assert Ok(coordinator_actor) =
    actor.new([]) |> actor.on_message(handle_coordinator_message) |> actor.start
  let coordinator_subject = coordinator_actor.data

  let ip = generate_simple_ip(0)
  let id = generate_identifier(ip)
  io.println("First ID is: ")
  echo id
  let m =
    { float.logarithm(int.to_float(nodes)) |> result.unwrap(1.0) }
    /. { float.logarithm(int.to_float(2)) |> result.unwrap(1.0) }
  let m = float.round(m) + 1

  let network_subject = initialize_network(id, m, requests, coordinator_subject)

  let actor_subject_list =
    list.range(1, nodes - 1)
    |> list.index_map(fn(node, idx) {
      let ip = generate_simple_ip(node)
      let bitarray = generate_identifier(ip)
      let finger_list = generate_base_finger_list(m)
      let assert Ok(actor) =
        actor.new(#(bitarray, None, None, finger_list, Config(0, m)))
        |> actor.on_message(handle_message)
        |> actor.start
      let subject = actor.data
      process.send_after(
        subject,
        joining_gap_milliseconds * { idx + 1 },
        Join(network_subject, subject),
      )

      process.send_after(
        coordinator_subject,
        joining_gap_milliseconds * { idx + 1 } + requests_gap_milliseconds,
        ReceiveRequest(
          coordinator_subject,
          generate_lookup_id(),
          subject,
          requests,
        ),
      )

      let stabilization_period = generate_waiting_period()
      let finger_fix_period = generate_waiting_period()

      process.send_after(
        subject,
        stabilization_period + joining_gap_milliseconds * { idx + 1 },
        Stabilize(subject),
      )
      process.send_after(
        subject,
        finger_fix_period + joining_gap_milliseconds * { idx + 1 },
        FixFingers(subject),
      )
      subject
    })

  termination_condition(coordinator_subject, nodes)
  Nil
}

fn closest_preceding_node(
  finger_list: List(Option(Node)),
  start: BitArray,
  end: BitArray,
) -> Option(Node) {
  let ans =
    list.reverse(finger_list)
    |> list.find(fn(node) {
      let is_valid = case node {
        Some(val) -> {
          let is_present = is_between_exclusive_exclusive(val.id, start, end)
          is_present
        }
        None -> False
      }
      is_valid
    })
  let fin = result.unwrap(ans, None)
  fin
}

type Message {
  Create(process.Subject(Message))
  FindSuccessor(id: BitArray, reply_to: process.Subject(#(Node, Int)))
  Join(process.Subject(Message), process.Subject(Message))
  Notify(BitArray, process.Subject(Message))
  GetPredecessor(process.Subject(Option(Node)))
  Stabilize(process.Subject(Message))
  FixFingers(process.Subject(Message))
}

fn handle_message(
  state: #(BitArray, Option(Node), Option(Node), List(Option(Node)), Config),
  message: Message,
) -> actor.Next(
  #(BitArray, Option(Node), Option(Node), List(Option(Node)), Config),
  Message,
) {
  case message {
    Create(subject) -> {
      let id = state.0
      let predecessor = None
      let successor = Node(id: id, subject: subject)
      io.println("Created network.")
      actor.continue(#(id, predecessor, Some(successor), state.3, state.4))
    }
    FindSuccessor(id, client) -> {
      let node_id = state.0
      let assert Some(succ) = state.2
      let successor_id = succ.id
      let successor_subject = succ.subject
      let is_present = is_between_exclusive_inclusive(id, node_id, successor_id)
      case is_present {
        True -> {
          io.println("Found successor.")
          echo succ
          process.send(client, #(succ, 0))
        }
        False -> {
          let closest_node = closest_preceding_node(state.3, node_id, id)
          let res = case closest_node {
            Some(node) -> {
              let res =
                process.call(node.subject, call_milliseconds, FindSuccessor(
                  state.0,
                  _,
                ))
              #(res.0, res.1 + 1)
            }
            None -> {
              let res =
                process.call(
                  successor_subject,
                  call_milliseconds,
                  FindSuccessor(state.0, _),
                )
              #(res.0, res.1 + 1)
            }
          }
          process.send(client, res)
        }
      }
      actor.continue(state)
    }
    Notify(possible_id, possible_subject) -> {
      // echo possible_id
      // echo possible_subject
      let node_id = state.0
      let predecessor_present = option.is_some(state.1)
      let updated_predecessor = case predecessor_present {
        True -> {
          let assert Some(pred) = state.1
          let is_present =
            is_between_exclusive_exclusive(possible_id, pred.id, node_id)
          case is_present {
            True -> Some(Node(possible_id, possible_subject))
            False -> Some(pred)
          }
        }
        False -> Some(Node(possible_id, possible_subject))
      }
      io.println("Updated Predecessor")
      echo updated_predecessor
      actor.continue(#(state.0, updated_predecessor, state.2, state.3, state.4))
    }
    Join(network_subject, my_subject) -> {
      io.println("Initiated Join now")
      let successor =
        process.call(network_subject, call_milliseconds, FindSuccessor(
          state.0,
          _,
        ))
      io.println("My Successor.")
      echo successor
      actor.send({ successor.0 }.subject, Notify(state.0, my_subject))
      actor.continue(#(state.0, None, Some(successor.0), state.3, state.4))
    }
    GetPredecessor(client) -> {
      process.send(client, state.1)
      actor.continue(state)
    }
    Stabilize(my_subject) -> {
      let node_id = state.0
      let assert Some(succ) = state.2
      let res = process.call(succ.subject, call_milliseconds, GetPredecessor)
      let updated_successor = case res {
        Some(val) -> {
          let in_between =
            is_between_exclusive_exclusive(val.id, node_id, succ.id)
          case in_between {
            True -> Some(val)
            False -> Some(succ)
          }
        }
        None -> Some(succ)
      }
      let assert Some(updated_successor_node) = updated_successor
      actor.send(updated_successor_node.subject, Notify(node_id, my_subject))
      process.send_after(
        my_subject,
        generate_waiting_period(),
        Stabilize(my_subject),
      )
      actor.continue(#(state.0, state.1, updated_successor, state.3, state.4))
    }
    FixFingers(my_subject) -> {
      let next = { state.4 }.counter + 1
      let updated_next = case next > { state.4 }.max {
        True -> 1
        False -> next
      }
      let finger_list = state.3
      let updated_finger_list =
        list.index_map(finger_list, fn(x, i) {
          case i == { updated_next - 1 } {
            True -> {
              let successor =
                process.call(my_subject, call_milliseconds, FindSuccessor(
                  add_power_of_2(state.0, i, 160),
                  _,
                ))
              Some(successor.0)
            }
            False -> x
          }
        })
      process.send_after(
        my_subject,
        generate_waiting_period(),
        FixFingers(my_subject),
      )
      actor.continue(#(
        state.0,
        state.1,
        state.2,
        updated_finger_list,
        Config(updated_next, { state.4 }.max),
      ))
    }
  }
}

type CoordinatorMessage {
  ReceiveRequest(
    process.Subject(CoordinatorMessage),
    BitArray,
    process.Subject(Message),
    Int,
  )
  GetStatus(process.Subject(Int))
}

fn handle_coordinator_message(
  state: List(#(process.Subject(Message), Bool)),
  message: CoordinatorMessage,
) -> actor.Next(List(#(process.Subject(Message), Bool)), CoordinatorMessage) {
  case message {
    ReceiveRequest(coordinator_subject, id, subject, requests) -> {
      let current_subjects = list.map(state, fn(entry) { entry.0 })
      let is_present = list.contains(current_subjects, subject)
      let updated_list = case is_present {
        True -> state
        False -> [#(subject, False), ..state]
      }
      process.send_after(
        coordinator_subject,
        requests_gap_milliseconds,
        ReceiveRequest(
          coordinator_subject,
          generate_lookup_id(),
          subject,
          requests - 1,
        ),
      )
      let complete_execution = requests <= 0
      let updated_list = case complete_execution {
        True -> {
          let new_list =
            list.filter(updated_list, fn(element) { element.0 != subject })
          let final_list = [#(subject, True), ..new_list]
        }
        False -> {
          process.call(subject, call_milliseconds, FindSuccessor(id, _))
          updated_list
        }
      }
      actor.continue(updated_list)
    }
    GetStatus(client) -> {
      let status_list = list.count(state, fn(entry) { entry.1 == True })
      actor.send(client, status_list)
      actor.continue(state)
    }
  }
}
