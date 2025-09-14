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

// fn get_random_neighbour(coordinate: Coordinate, config: Config) -> Coordinate {
//   let possible_neighbours = []
//   let topo = config.topo
//   let is_linear = list.contains(linear_topos, topo)
//   coordinate
// }

fn filter_neighbours(
  possible_neighbours: List(Coordinate),
  side: Int,
  subject: process.Subject(Message(e)),
  actor_dict: dict.Dict(Coordinate, process.Subject(Message(e))),
) -> List(#(Coordinate, process.Subject(Message(e)))) {
  let filtered_list =
    list.filter_map(possible_neighbours, fn(possible_neighbour) {
      let is_valid = is_valid_neighbour(possible_neighbour, side)
      let entry = case is_valid {
        True -> {
          let entry =
            dict.get(actor_dict, possible_neighbour)
            |> result.unwrap(subject)
          Ok(#(possible_neighbour, entry))
        }
        False -> Error(Nil)
      }
      entry
    })
  filtered_list
}

fn is_valid_neighbour(coordinate: Coordinate, side: Int) -> Bool {
  let is_valid =
    coordinate.x >= 0
    && coordinate.x < side
    && coordinate.y >= 0
    && coordinate.y < side
    && coordinate.z >= 0
    && coordinate.z < side
  is_valid
}

fn possible_neighbours(
  coordinate: Coordinate,
  x1: List(Int),
  y1: List(Int),
  z1: List(Int),
) -> List(Coordinate) {
  let possible_neighbours =
    x1
    |> list.flat_map(fn(x) {
      y1
      |> list.flat_map(fn(y) {
        z1
        |> list.map(fn(z) {
          let new_coordinate =
            Coordinate(coordinate.x + x, coordinate.y + y, coordinate.z + z)
          new_coordinate
        })
      })
    })
  possible_neighbours
}

fn construct_neighbours(
  actor_list: List(#(Coordinate, process.Subject(Message(e)))),
  actor_dict: dict.Dict(Coordinate, process.Subject(Message(e))),
  topo: String,
  side: Int,
) {
  case topo {
    "full" -> {
      list.each(actor_list, fn(actor) {
        let _coordinate = actor.0
        let subject = actor.1
        actor.send(subject, Construct(actor_list))
      })
    }
    "line" -> {
      list.each(actor_list, fn(actor) {
        let coordinate = actor.0
        let subject = actor.1
        let l = [-1, 1]
        let possible_neighbours =
          list.map(l, fn(x1) {
            Coordinate(coordinate.x + x1, coordinate.y, coordinate.z)
          })
        let filtered_list =
          filter_neighbours(possible_neighbours, side, subject, actor_dict)
        actor.send(subject, Construct(filtered_list))
      })
    }
    "3D" -> {
      list.each(actor_list, fn(actor) {
        let coordinate = actor.0
        let subject = actor.1
        let x1 = [1, -1, 0, 0, 0, 0]
        let y1 = [0, 0, 1, -1, 0, 0]
        let z1 = [0, 0, 0, 0, 1, -1]
        let possible_neighbours = possible_neighbours(coordinate, x1, y1, z1)
        let filtered_list =
          filter_neighbours(possible_neighbours, side, subject, actor_dict)
        actor.send(subject, Construct(filtered_list))
      })
    }
    "imp3D" -> {
      list.each(actor_list, fn(actor) {
        let coordinate = actor.0
        let subject = actor.1
        let x1 = [1, -1, 0, 0, 0, 0]
        let y1 = [0, 0, 1, -1, 0, 0]
        let z1 = [0, 0, 0, 0, 1, -1]
        let possible_neighbours = possible_neighbours(coordinate, x1, y1, z1)
        let filtered_list =
          filter_neighbours(possible_neighbours, side, subject, actor_dict)

        //TODO  Randomized Neighbour Selection
        actor.send(subject, Construct(filtered_list))
      })
    }
    _ -> {
      io.println("Invalid Configuration.")
    }
  }
}

fn construct_actor_list(
  side: Int,
  is_linear: Bool,
) -> List(#(Coordinate, process.Subject(Message(e)))) {
  let x_max = side - 1
  let y_max = case is_linear {
    True -> 0
    False -> side - 1
  }
  let z_max = case is_linear {
    True -> 0
    False -> side - 1
  }
  let x_range = list.range(0, x_max)
  let y_range = list.range(0, y_max)
  let z_range = list.range(0, z_max)

  let actor_list =
    x_range
    |> list.flat_map(fn(x) {
      y_range
      |> list.flat_map(fn(y) {
        z_range
        |> list.map(fn(z) {
          let coordinate = Coordinate(x, y, z)

          // build actor
          let assert Ok(actor) =
            actor.new(#(coordinate, []))
            |> actor.on_message(handle_message)
            |> actor.start()

          let subject = actor.data
          #(coordinate, subject)
        })
      })
    })
  actor_list
}

pub fn simulate(
  side: Int,
  topo: String,
  algorithm: String,
  is_linear: Bool,
) -> Nil {
  let generator = random.int(1, side)

  let actor_list = construct_actor_list(side, is_linear)
  let actor_dict = dict.from_list(actor_list)

  construct_neighbours(actor_list, actor_dict, topo, side)
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
  Construct(List(#(Coordinate, process.Subject(Message(element)))))
}

fn handle_message(
  state: #(Coordinate, List(#(Coordinate, process.Subject(Message(e))))),
  message: Message(e),
) -> actor.Next(
  #(Coordinate, List(#(Coordinate, process.Subject(Message(e))))),
  Message(element),
) {
  case message {
    Construct(value) -> {
      let updated_state = #(state.0, value)
      actor.continue(updated_state)
    }
    SendMessage(value) -> {
      todo
    }
  }
}
