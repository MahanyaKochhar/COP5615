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

type Node {
  Node(id: BitArray, subject: process.Subject(Message))
}

type BackgroundKey {
  BackgroundKey(subject: process.Subject(Message), stabilization_period: Int)
}

type Config {
  Config(counter: Int, max: Int)
}

// fn background_process(background_key_list: List(BackgroundKey), terminate: Bool) {
//   case terminate {
//     True -> True
//     False -> {
//       let updated_background_key_list =
//         list.map(background_key_list, fn(background_key) {
//           let subject = background_key.subject

//           let last_executed_stabilization_unix =
//             background_key.last_executed_stabilization_unix
//           let last_executed_finger_fix_unix =
//             background_key.last_executed_finger_fix_unix

//           let current_unix =
//             timestamp.system_time() |> timestamp.to_unix_seconds()

//           let updated_stabilization_unix = case
//             current_unix
//             >. last_executed_stabilization_unix
//             + background_key.stabilization_period
//           {
//             True -> {
//               actor.send(subject, Stabilize(subject))
//               current_unix
//             }
//             False -> last_executed_stabilization_unix
//           }

//           let updated_finger_fix_unix = case
//             current_unix
//             >. last_executed_finger_fix_unix + background_key.finger_fix_period
//           {
//             True -> {
//               actor.send(subject, FixFingers(subject))
//               current_unix
//             }
//             False -> last_executed_finger_fix_unix
//           }

//           let stabilization_period = case
//             updated_stabilization_unix == last_executed_stabilization_unix
//           {
//             True -> background_key.stabilization_period
//             False -> {
//               generate_waiting_period()
//             }
//           }

//           let finger_fix_period = case
//             updated_finger_fix_unix == last_executed_finger_fix_unix
//           {
//             True -> background_key.finger_fix_period
//             False -> {
//               generate_waiting_period()
//             }
//           }

//           BackgroundKey(
//             subject: subject,
//             stabilization_period: stabilization_period,
//             finger_fix_period: finger_fix_period,
//             last_executed_stabilization_unix: updated_stabilization_unix,
//             last_executed_finger_fix_unix: updated_finger_fix_unix,
//           )
//         })
//       background_process(updated_background_key_list, False)
//     }
//   }
// }

fn background_process(background_key: BackgroundKey) {
  process.sleep(background_key.stabilization_period)
  let subject = background_key.subject
  actor.send(subject, Stabilize(subject))
  process.sleep(5000)
  actor.send(subject, FixFingers(subject))
  background_process(background_key)
}

fn node_workflow(background_key: BackgroundKey) {
  process.spawn(fn() { background_process(background_key) })
}

fn generate_waiting_period() -> Int {
  let generator = random.int(0, 30)
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

fn generate_identifier(str: String) -> BitArray {
  let digest = crypto.hash(crypto.Sha1, bit_array.from_string(str))
}

fn generate_base_finger_list(m: Int) -> List(Option(Node)) {
  list.range(1, m)
  |> list.map(fn(_idx) { None })
}

fn initialize_network(id: BitArray, m: Int) -> BackgroundKey {
  let finger_list = generate_base_finger_list(m)
  let assert Ok(actor) =
    actor.new(#(id, None, None, finger_list, Config(0, m)))
    |> actor.on_message(handle_message)
    |> actor.start
  let subject = actor.data
  actor.send(subject, Create(subject))
  let stabilization_period = generate_waiting_period()
  let background_key =
    BackgroundKey(subject: subject, stabilization_period: stabilization_period)
  process.spawn(fn() {
    node_workflow(background_key)
    background_process(background_key)
  })
  background_key
}

pub fn start_simulation(nodes: Int, requests: Int) -> Nil {
  io.println("Start simulation.")
  let ip = generate_simple_ip(0)
  let id = generate_identifier(ip)
  io.println("First ID is: ")
  echo id
  let m =
    { float.logarithm(int.to_float(nodes)) |> result.unwrap(1.0) }
    /. { float.logarithm(int.to_float(2)) |> result.unwrap(1.0) }
  let m = float.round(m) + 1
  let root_background_key = initialize_network(id, m)
  let actor_subject_list =
    list.range(1, nodes - 1)
    |> list.map(fn(node) {
      let ip = generate_simple_ip(node)
      let bitarray = generate_identifier(ip)
      let finger_list = generate_base_finger_list(m)
      let assert Ok(actor) =
        actor.new(#(bitarray, None, None, finger_list, Config(0, m)))
        |> actor.on_message(handle_message)
        |> actor.start
      let subject = actor.data
      actor.send(subject, Join(root_background_key.subject, subject))
      process.sleep(5000)
      let stabilization_period = generate_waiting_period()
      let finger_fix_period = generate_waiting_period()
      let background_key =
        BackgroundKey(
          subject: subject,
          stabilization_period: stabilization_period,
        )
      process.spawn(fn() { background_process(background_key) })
      background_key
    })
  process.sleep(5000)
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
  FindSuccessor(id: BitArray, reply_to: process.Subject(Node))
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
          process.send(client, succ)
        }
        False -> {
          let closest_node = closest_preceding_node(state.3, node_id, id)
          let res = case closest_node {
            Some(node) ->
              process.call(node.subject, call_milliseconds, FindSuccessor(
                state.0,
                _,
              ))
            None ->
              process.call(successor_subject, call_milliseconds, FindSuccessor(
                state.0,
                _,
              ))
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
      actor.send(successor.subject, Notify(state.0, my_subject))
      actor.continue(#(state.0, None, Some(successor), state.3, state.4))
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
              Some(successor)
            }
            False -> x
          }
        })
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
