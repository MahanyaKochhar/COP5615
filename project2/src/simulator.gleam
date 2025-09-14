import gleam/dict
import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/list
import gleam/otp/actor
import gleam/result
import prng/random

const linear_topos = ["full", "line"]

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
  is_linear: Bool,
) -> dict.Dict(Coordinate, process.Subject(Message(e))) {
  let x_max = n - 1
  let y_max = case is_linear {
    True -> 0
    False -> n - 1
  }
  let z_max = case is_linear {
    True -> 0
    False -> n - 1
  }
  let x = list.range(0, x_max)
  let y = list.range(0, y_max)
  let z = list.range(0, z_max)
  let actor_list = []
  list.each(x, fn(x1) {
    list.each(y, fn(y1) {
      list.each(z, fn(z1) {
        let coordinate = Coordinate(x1, y1, z1)
        let assert Ok(actor) =
          actor.new(#(coordinate, []))
          |> actor.on_message(handle_message)
          |> actor.start()
        let subject = actor.data
        let actor_list = list.append(actor_list, [#(coordinate, subject)])
        echo actor_list
      })
    })
  })
  echo actor_list
  let actor_dict = dict.from_list(actor_list)
}

pub fn simulate(n: Int, topo: String, algorithm: String, is_linear: Bool) -> Nil {
  let generator = random.int(1, n)

  let actor_dict = construct_actor_dict(n, is_linear)
  // let x_idx = random.random_sample(generator)
  // let y_idx = case is_linear {
  //   True -> 0
  //   False -> random.random_sample(generator)
  // }
  // let z_idx = case is_linear {
  //   True -> 0
  //   False -> random.random_sample(generator)
  // }

  // let chosen = #(x_idx, y_idx, z_idx)

  Nil
}

type Message(element) {
  SendMessage(element)
}

fn handle_message(
  state: #(Coordinate, List(process.Subject(Message(e)))),
  message: Message(e),
) -> actor.Next(
  #(Coordinate, List(process.Subject(Message(e)))),
  Message(element),
) {
  todo
}
