import gleam/list
import prng/random

const linear_topos = ["full", "line"]

pub fn simulate(n: Int, topo: String, algorithm: String) -> Nil {
  let generator = random.int(1, n)
  let is_linear = list.contains(linear_topos, topo)
  let x_idx = random.random_sample(generator)
  let y_idx = case is_linear {
    True -> 0
    False -> random.random_sample(generator)
  }
  let z_idx = case is_linear {
    True -> 0
    False -> random.random_sample(generator)
  }
  Nil
}
