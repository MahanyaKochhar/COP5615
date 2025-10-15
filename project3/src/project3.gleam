import actors
import argv
import gleam/int
import gleam/io
import gleam/result

pub fn main() -> Nil {
  case argv.load().arguments {
    [num_nodes, num_requests] -> {
      let nodes = int.base_parse(num_nodes, 10) |> result.unwrap(-1)
      let requests = int.base_parse(num_requests, 10) |> result.unwrap(-1)
      case nodes > 0 && requests > 0 {
        True -> actors.start_simulation(nodes, requests)
        False -> io.println("Inputs are bad.")
      }
    }
    _ -> io.println("Invalid Arguments.")
  }
}
