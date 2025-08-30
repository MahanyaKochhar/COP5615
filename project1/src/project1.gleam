import argv
import gleam/int
import gleam/io
import gleam/result

pub fn main() -> Nil {
  let ans = case argv.load().arguments {
    [a, b] -> solve(a, b)
    _ -> -1
  }
  case ans {
    -1 -> io.println("Invalid Inputs.")
    _ -> io.println(int.to_string(ans))
  }
}

fn solve(astr: String, bstr: String) -> Int {
  let a = int.base_parse(astr, 10)
  let b = int.base_parse(bstr, 10)
  let n = result.unwrap(a, -1)
  let k = result.unwrap(b, -1)
  let result = case n > -1 && k > -1 {
    True -> find_solution(n, k)
    False -> -1
  }
  result
}

fn find_solution(n: Int, k: Int) -> Int {
  1
}
