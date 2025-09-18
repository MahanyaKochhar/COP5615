import gleam/dict
import gleam/erlang/process
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/otp/actor
import gleam/result
import prng/random

const rumour = "Top Secret"

const near_list = [
  #(1, 0, 0),
  #(-1, 0, 0),
  #(0, 1, 0),
  #(0, -1, 0),
  #(0, 0, 1),
  #(0, 0, -1),
]

const rumour_cnt = 10

pub type Coordinate {
  Coordinate(x: Int, y: Int, z: Int)
}

pub type Rumour {
  Rumour(rumour: String, cnt: Int)
}

pub type PushSum {
  PushSum(s: Float, w: Float, ratio: Float, cnt: Int)
}

fn get_random_neighbour(
  coordinate: Coordinate,
  new_coordinate: Coordinate,
  generator: random.Generator(Int),
) -> Coordinate {
  let random_neighbour = case
    int.absolute_value(new_coordinate.x - coordinate.x)
    + int.absolute_value(new_coordinate.y - coordinate.y)
    + int.absolute_value(new_coordinate.z - coordinate.z)
    > 1
  {
    True -> new_coordinate
    _ -> {
      let x = random.random_sample(generator)
      let y = random.random_sample(generator)
      let z = random.random_sample(generator)
      get_random_neighbour(coordinate, Coordinate(x, y, z), generator)
    }
  }
  random_neighbour
}

fn filter_neighbours(
  possible_neighbours: List(Coordinate),
  side: Int,
  subject: process.Subject(Message),
  actor_dict: dict.Dict(Coordinate, process.Subject(Message)),
) -> List(#(Coordinate, process.Subject(Message))) {
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
  near_list: List(#(Int, Int, Int)),
) -> List(Coordinate) {
  let possible_neighbours =
    list.map(near_list, fn(element) {
      let new_coordinate =
        Coordinate(
          coordinate.x + element.0,
          coordinate.y + element.1,
          coordinate.z + element.2,
        )
      new_coordinate
    })
  possible_neighbours
}

fn construct_neighbours(
  actor_list: List(#(Coordinate, process.Subject(Message))),
  actor_dict: dict.Dict(Coordinate, process.Subject(Message)),
  topo: String,
  side: Int,
) {
  case topo {
    "full" -> {
      list.each(actor_list, fn(actor) {
        let coordinate = actor.0
        let subject = actor.1
        let filtered_list =
          list.filter(actor_list, fn(member) { member.0 != coordinate })
        actor.send(subject, Construct(filtered_list))
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
        let possible_neighbours = possible_neighbours(coordinate, near_list)
        let filtered_list =
          filter_neighbours(possible_neighbours, side, subject, actor_dict)
        actor.send(subject, Construct(filtered_list))
      })
    }
    "imp3D" -> {
      let generator = random.int(0, side - 1)
      list.each(actor_list, fn(actor) {
        let coordinate = actor.0
        let subject = actor.1
        let possible_neighbours = possible_neighbours(coordinate, near_list)
        let filtered_list =
          filter_neighbours(possible_neighbours, side, subject, actor_dict)
        let random_neighbour =
          get_random_neighbour(coordinate, coordinate, generator)
        let random_neighbour_list =
          filter_neighbours([random_neighbour], side, subject, actor_dict)
        let updated_list = list.append(filtered_list, random_neighbour_list)
        actor.send(subject, Construct(updated_list))
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
) -> List(#(Coordinate, process.Subject(Message))) {
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
          let idx =
            x + y * { y_max + 1 } + z * { { y_max + 1 } * { x_max + 1 } }
          // build actor
          let assert Ok(actor) =
            actor.new(#(
              coordinate,
              Rumour(rumour: "", cnt: 0),
              PushSum(s: int.to_float(idx), w: 1.0, ratio: 0.0, cnt: 0),
              [],
              False,
            ))
            |> actor.on_message(handle_message)
            |> actor.start()

          let subject = actor.data
          #(coordinate, subject)
        })
      })
    })
  actor_list
}

fn get_index(
  actor_list: List(#(Coordinate, process.Subject(Message))),
  idx: Int,
) -> #(Coordinate, process.Subject(Message)) {
  let assert Ok(dummy_actor) =
    actor.new(#(
      Coordinate(0, 0, 0),
      Rumour(rumour: "", cnt: 0),
      PushSum(s: 0.0, w: 1.0, ratio: 0.0, cnt: 0),
      [],
      False,
    ))
    |> actor.on_message(handle_message)
    |> actor.start()

  let subject = dummy_actor.data
  let valid_list =
    list.index_map(actor_list, fn(x, i) { #(i, x) })
    |> list.filter(fn(x) { x.0 == idx })
  let valid =
    list.first(valid_list)
    |> result.unwrap(#(-1, #(Coordinate(0, 0, 0), subject)))
  valid.1
}

fn validate_termination(
  actor_list: List(#(Coordinate, process.Subject(Message))),
  terminate: Bool,
) {
  case terminate {
    True -> Nil
    False -> {
      let arr =
        list.filter(actor_list, fn(actor) {
          actor.call(actor.1, 100, GetStatus) |> result.unwrap(False)
        })
      validate_termination(actor_list, list.length(arr) > 0)
    }
  }
}

pub fn simulate(
  side: Int,
  topo: String,
  algorithm: String,
  is_linear: Bool,
) -> Nil {
  let actor_list = construct_actor_list(side, is_linear)
  io.println("Length of Actor List " <> int.to_string(list.length(actor_list)))
  io.println("Actor List")
  echo actor_list
  let actor_dict = dict.from_list(actor_list)
  construct_neighbours(actor_list, actor_dict, topo, side)
  let random_selection = get_random_neighbour_within_list(actor_list)
  case algorithm {
    "gossip" -> {
      io.println("Gossip Algorithm")
      actor.send(random_selection.1, SendRumour(rumour))
    }
    "push-sum" -> {
      io.println("Push Sum Algorithm")
      actor.send(random_selection.1, SendPushSum(0.0, 0.0))
    }
    _ -> Nil
  }
  validate_termination(actor_list, False)
  // process.sleep(5000)
  Nil
}

fn get_random_neighbour_within_list(
  actor_list: List(#(Coordinate, process.Subject(Message))),
) -> #(Coordinate, process.Subject(Message)) {
  let generator = random.int(0, list.length(actor_list) - 1)
  let random_idx = random.random_sample(generator)
  io.println("Random Index " <> int.to_string(random_idx))
  let random_selection = get_index(actor_list, random_idx)
  random_selection
}

type Message {
  SendRumour(String)
  Construct(List(#(Coordinate, process.Subject(Message))))
  GetStatus(process.Subject(Result(Bool, Nil)))
  SendPushSum(Float, Float)
}

fn handle_message(
  state: #(
    Coordinate,
    Rumour,
    PushSum,
    List(#(Coordinate, process.Subject(Message))),
    Bool,
  ),
  message: Message,
) -> actor.Next(
  #(
    Coordinate,
    Rumour,
    PushSum,
    List(#(Coordinate, process.Subject(Message))),
    Bool,
  ),
  Message,
) {
  case message {
    Construct(value) -> {
      io.println("Neighbours of Coordinate")
      echo #(state.0, value)
      let updated_state = #(state.0, state.1, state.2, value, state.4)
      actor.continue(updated_state)
    }
    SendRumour(rumour) -> {
      let existing_cnt = { state.1 }.cnt
      io.println("Existing Cnt " <> int.to_string(existing_cnt))
      let new_cnt = existing_cnt + 1
      io.println("New Cnt " <> int.to_string(new_cnt))
      case new_cnt > rumour_cnt {
        True -> Nil
        False -> {
          let neighbours_list = state.3
          let random_selection =
            get_random_neighbour_within_list(neighbours_list)
          actor.send(random_selection.1, SendRumour(rumour))
        }
      }
      let terminate = new_cnt > rumour_cnt
      let updated_state = #(
        state.0,
        Rumour(rumour: rumour, cnt: new_cnt),
        state.2,
        state.3,
        terminate,
      )
      actor.continue(updated_state)
    }
    SendPushSum(s, w) -> {
      let original = state.2
      let s1 = original.s
      let w1 = original.w
      let previous_ratio = original.ratio
      let previous_cnt = original.cnt
      let s2 = s1 +. s
      let w2 = w1 +. w
      let new_ratio = s2 /. w2
      let power = float.power(10.0, -10.0) |> result.unwrap(0.0)
      let diff = float.absolute_value(new_ratio -. previous_ratio)
      let new_s = s2 /. 2.0
      let new_w = s2 /. 2.0
      let terminate = case diff <. power && { previous_cnt + 1 } == 3 {
        True -> True
        False -> {
          let neighbours_list = state.3
          let random_selection =
            get_random_neighbour_within_list(neighbours_list)
          actor.send(random_selection.1, SendPushSum(new_s, new_w))
          False
        }
      }
      let cnt = case diff <. power {
        True -> previous_cnt + 1
        False -> 0
      }
      let updated_state = #(
        state.0,
        state.1,
        PushSum(s: new_s, w: new_w, ratio: new_ratio, cnt: cnt),
        state.3,
        terminate,
      )
      actor.continue(updated_state)
    }
    GetStatus(client) -> {
      actor.send(client, Ok(state.4))
      actor.continue(state)
    }
  }
}
