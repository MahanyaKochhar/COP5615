import gleam/bit_array
import gleam/crypto
import gleam/int
import gleam/order.{Eq, Gt, Lt}
import prng/random

pub fn generate_waiting_period() -> Int {
  //   let generator = random.int(10, 25)
  //   let period = random.random_sample(generator)
  //   period * 1000
  15_000
}

pub fn generate_simple_ip(node: Int) -> String {
  "ip-address" <> "." <> int.to_string(node)
}

pub fn generate_identifier(str: String) -> BitArray {
  let _digest = crypto.hash(crypto.Sha1, bit_array.from_string(str))
}

pub fn generate_lookup_id() -> BitArray {
  let generator = random.int(100, 300_000)
  let node_val = random.random_sample(generator)
  let ip = generate_simple_ip(node_val)
  let id = generate_identifier(ip)
  id
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
