import argv
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set
import simulator

const linear_topos = ["full", "line"]

fn validate(n: Int, topo: String, algorithm: String) -> Bool {
  let valid_nodes = {
    n > 0
  }
  let valid_algo = { algorithm == "gossip" } || { algorithm == "push-sum" }
  let valid_topos = set.from_list(["full", "3D", "line", "imp3D"])
  let valid_topo = set.contains(valid_topos, topo)
  valid_nodes && valid_algo && valid_topo
}

fn side_length(n: Int) -> Int {
  let side = int.power(n, 1.0 /. 3.0) |> result.unwrap(0.0) |> float.round()
  side
}

pub fn main() -> Nil {
  case argv.load().arguments {
    [n, topo, algorithm] -> {
      let nodes = int.base_parse(n, 10) |> result.unwrap(-1)
      let validation = validate(nodes, topo, algorithm)
      let is_linear = list.contains(linear_topos, topo)
      let side = case is_linear {
        True -> nodes
        False -> {
          side_length(nodes)
        }
      }
      case validation && side > 0 {
        True -> simulator.simulate(side, topo, algorithm, is_linear)
        False -> io.println("Inputs are bad.")
      }
    }
    _ -> io.println("Invalid Command Line Arguments.")
  }
}
