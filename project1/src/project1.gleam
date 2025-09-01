import argv
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import working_actors

pub fn main() -> Nil {
  let ans = case argv.load().arguments {
    [a, b] -> solve(a, b)
    _ -> []
  }
  case ans {
    [] -> io.println("Invalid Inputs.")
    _ -> list.each(ans, fn(x) { io.println(int.to_string(x)) })
  }
}

fn solve(astr: String, bstr: String) -> List(Int) {
  let n = int.base_parse(astr, 10) |> result.unwrap(-1)
  let k = int.base_parse(bstr, 10) |> result.unwrap(-1)
  let result = find_solution(n, k)
  result
}

fn find_solution(n: Int, k: Int) -> List(Int) {
  let l = list.range(1, n)
  let ans =
    working_actors.spawn_workers(n, l, fn(s) {
      let sumsquares =
        list.range(s, s + k - 1)
        |> list.map(fn(x) { x * x })
        |> list.fold(0, fn(acc, x) { acc + x })
      let root =
        int.square_root(sumsquares) |> result.unwrap(0.0) |> float.floor()
      let result = case root *. root == int.to_float(sumsquares) {
        True -> s
        False -> -1
      }
      result
    })
  let fin = list.filter(ans, fn(x) { x != -1 })
  fin
}
