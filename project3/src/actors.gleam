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

// fn generate_ip_address(dictionary) -> String {
//   let generator = random.int(0, 255)
//   let octet1 = random.random_sample(generator)
//   let octet2 = random.random_sample(generator)
//   let octet3 = random.random_sample(generator)
//   let octet4 = random.random_sample(generator)
//   let ip =
//     int.to_string(octet1)
//     <> "."
//     <> int.to_string(octet3)
//     <> "."
//     <> int.to_string(octet4)
//   case dict.has_key(dictionary, ip) {
//     True -> ip
//     False -> generate_ip_address(dictionary)
//   }
// }

const call_milliseconds = 50_000

type Node {
  Node(id: BitArray, subject: process.Subject(Message))
}

pub fn is_between_circular(id: BitArray, start: BitArray, end: BitArray) -> Bool {
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

fn initialize_network(id: BitArray, m: Int) -> process.Subject(Message) {
  let finger_list = generate_base_finger_list(m)
  let assert Ok(actor) =
    actor.new(#(id, None, None, finger_list))
    |> actor.on_message(handle_message)
    |> actor.start
  let subject = actor.data
  actor.send(subject, Create(subject))
  subject
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
  let root_subject = initialize_network(id, m)
  list.range(1, nodes - 1)
  |> list.map(fn(node) {
    let ip = generate_simple_ip(node)
    let bitarray = generate_identifier(ip)
    let finger_list = generate_base_finger_list(m)
    let assert Ok(actor) =
      actor.new(#(bitarray, None, None, finger_list))
      |> actor.on_message(handle_message)
      |> actor.start
    let subject = actor.data
    actor.send(subject, Join(root_subject, subject))
    process.sleep(5000)
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
          let is_present = is_between_circular(val.id, start, end)
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
}

fn handle_message(
  state: #(BitArray, Option(Node), Option(Node), List(Option(Node))),
  message: Message,
) -> actor.Next(
  #(BitArray, Option(Node), Option(Node), List(Option(Node))),
  Message,
) {
  case message {
    Create(subject) -> {
      let id = state.0
      let predecessor = None
      let successor = Node(id: id, subject: subject)
      io.println("Created network.")
      actor.continue(#(id, predecessor, Some(successor), state.3))
    }
    FindSuccessor(id, client) -> {
      let node_id = state.0
      let assert Some(succ) = state.2
      let successor_id = succ.id
      let successor_subject = succ.subject
      let is_present = is_between_circular(id, node_id, successor_id)
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
          let is_present = is_between_circular(possible_id, pred.id, node_id)
          case is_present {
            True -> Some(Node(possible_id, possible_subject))
            False -> Some(pred)
          }
        }
        False -> Some(Node(possible_id, possible_subject))
      }
      io.println("Updated Predecessor")
      echo updated_predecessor
      actor.continue(#(state.0, updated_predecessor, state.2, state.3))
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
      actor.continue(#(state.0, None, Some(successor), state.3))
    }
  }
}
