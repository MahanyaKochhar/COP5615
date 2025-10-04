import gleam/bit_array
import gleam/crypto
import gleam/dict
import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/otp/actor
import prng/random

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

type Successor {
  Successor(id: BitArray, subject: process.Subject(Message))
}

type Predecessor {
  Predecessor(id: BitArray, subject: process.Subject(Message))
}

pub fn is_greater_than(a: BitArray, b: BitArray) -> Bool {
  bit_array.compare(a, b) == order.Gt
}

pub fn is_less_or_equal(a: BitArray, b: BitArray) -> Bool {
  bit_array.compare(a, b) != order.Gt
}

fn generate_simple_ip(node: Int) -> String {
  "ip-address" <> "." <> int.to_string(node)
}

fn generate_identifier(str: String) -> BitArray {
  let digest = crypto.hash(crypto.Sha1, bit_array.from_string(str))
}

fn initialize_network(id: BitArray) -> process.Subject(Message) {
  let assert Ok(actor) =
    actor.new(#(id, None, None))
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
  let network_subject = initialize_network(id)

  list.range(1, nodes - 1)
  |> list.map(fn(node) {
    let ip = generate_simple_ip(node)
    let bitarray = generate_identifier(ip)
    echo bitarray
  })
  Nil
}

type Message {
  Create(process.Subject(Message))
  FindSuccessor(BitArray)
}

fn handle_message(
  state: #(BitArray, Option(Predecessor), Option(Successor)),
  message: Message,
) -> actor.Next(#(BitArray, Option(Predecessor), Option(Successor)), Message) {
  case message {
    Create(subject) -> {
      let id = state.0
      let predecessor = None
      let successor = Successor(id: id, subject: subject)
      actor.continue(#(id, predecessor, Some(successor)))
    }
    FindSuccessor(id) -> {
      let node_id = state.0
      let assert Some(succ) = state.2
      let successor_id = succ.id
      let successor_subject = succ.subject
      let is_present =
        is_greater_than(id, node_id) && is_less_or_equal(node_id, successor_id)
      case is_present {
        True -> Nil
        False -> actor.send(successor_subject, FindSuccessor(id))
      }
      actor.continue(state)
    }
  }
}
