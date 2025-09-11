import gleam/dict
import gleam/erlang/process
import gleam/list
import gleam/otp/actor
import prng/random

const linear_topos = ["full", "line"]
const dict = dict.new()
pub type Coordinate {
  Coordinate(x: Int, y: Int, z: Int)
}

pub type Rumour {
  Rumour(rumour: String, cnt: Int)
}

pub type Config {
  Config(topo: String, n: Int)
}

fn get_random_neighbour(coordinate: Coordinate, config: Config) -> Coordinate {
  let possible_neighbours = []
  let topo = config.topo
  let is_linear = list.contains(linear_topos, topo)
  coordinate
}

fn construct_actor_dict(
  n: Int,
  is_linear: Int,
) -> dict.Dict(Coordinate, process.Subject(Message(e))) {
  let actor = actor.new(Nil) |> actor.on_message(handle_message) |> actor.start
}

pub fn simulate(n: Int, topo: String, algorithm: String) -> Nil {
  let generator = random.int(1, n)
  let is_linear = list.contains(linear_topos, topo)

  construct_actor_dict(n, is_linear)

  let x_idx = random.random_sample(generator)
  let y_idx = case is_linear {
    True -> 0
    False -> random.random_sample(generator)
  }
  let z_idx = case is_linear {
    True -> 0
    False -> random.random_sample(generator)
  }

  let chosen = #(x_idx, y_idx, z_idx)

  Nil
}

type Message(element) {
  SendMessage(element)
}

fn handle_message(
  state: #(Coordinate, Config, Rumour),
  message: Message(e),
) -> actor.Next(#(Coordinate, Config, Rumour), Message(element)) {
  case message {
    SendMessage(msg) -> {
      let random_neighbour = get_random_neighbour(state.0, state.1)
    }
  }
}
