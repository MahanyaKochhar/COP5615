import actors
import argv
import gleam/int
import gleam/io
import gleam/result

pub type Config {
  Config(a: String, b: String, c: String)
}

fn default_config(a: String, b: String) -> Config {
  Config(a, b, "0")
}

pub fn main() -> Nil {
  let ans = case argv.load().arguments {
    [a, b, c] -> solve(Config(a, b, c))
    [a, b] -> solve(default_config(a, b))
    _ -> False
  }
  case ans {
    False -> io.println("Invalid Inputs.")
    _ -> Nil
  }
}

fn solve(config: Config) -> Bool {
  let n = int.base_parse(config.a, 10) |> result.unwrap(-1)
  let k = int.base_parse(config.b, 10) |> result.unwrap(-1)
  let step = int.base_parse(config.c, 10) |> result.unwrap(0)
  let result = case n > 0 && k > 0 {
    True -> actors.work(n, k, step)
    False -> False
  }
  result
}
