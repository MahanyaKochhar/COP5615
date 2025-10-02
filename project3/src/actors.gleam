import gleam/bit_array
import gleam/crypto
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
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
//     <> int.to_string(octet2)
//     <> "."
//     <> int.to_string(octet3)
//     <> "."
//     <> int.to_string(octet4)
//   case dict.has_key(dictionary, ip) {
//     True -> ip
//     False -> generate_ip_address(dictionary)
//   }
// }

fn generate_simple_ip(node: Int) -> String {
  "ip-address" <> "." <> int.to_string(node)
}

fn generate_identifier(str: String) {
  let digest = crypto.hash(crypto.Sha1, bit_array.from_string(str))
}

pub fn start_simulation(nodes: Int, requests: Int) -> Nil {
  io.println("Start simulation.")
  list.range(0, nodes - 1)
  |> list.map(fn(node) {
    let ip = generate_simple_ip(node)
  })
  Nil
}

type Message {
  Create(Int)
}

fn handle_message(
  state: List(Int),
  message: Message,
) -> actor.Next(List(Int), Message) {
  case message {
    
  }
}
