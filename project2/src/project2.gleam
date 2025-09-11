import argv
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import simulator

fn validate(n: Int, topo: String, algorithm: String) -> Bool {
  let valid_nodes = {
    n > 0
  }
  let valid_algo = { algorithm == "gossip" } || { algorithm == "push-sum" }
  let valid_topos = ["full", "3D", "line", "imp3D"]
  let valid_topo = list.contains(valid_topos, topo)
  valid_nodes && valid_algo && valid_topo
}

pub fn main() -> Nil {
  case argv.load().arguments {
    [n, topo, algorithm] -> {
      let nodes = int.base_parse(n, 10) |> result.unwrap(-1)
      let validation = validate(nodes, topo, algorithm)
      case validation {
        True -> simulator.simulate(nodes, topo, algorithm)
        False -> io.println("Inputs are bad.")
      }
    }
    _ -> io.println("Invalid Command Line Arguments.")
  }
}
