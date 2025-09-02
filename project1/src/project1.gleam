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
    _ -> [-1]
  }
  case ans {
    [-1] -> io.println("Invalid Inputs.")
    _ -> Nil
  }
}

fn solve(astr: String, bstr: String) -> List(Int) {
  let n = int.base_parse(astr, 10) |> result.unwrap(-1)
  let k = int.base_parse(bstr, 10) |> result.unwrap(-1)
  let result = case n > -1 && k > -1 && n >= k {
    True -> find_solution(n, k)
    False -> []
  }
  result
}

fn batch(n: Int, step: Int) -> List(Int) {
  let units =
    list.range(1, n)
    |> list.filter(fn(x) { { x - 1 } % step == 0 })
  units
}

fn find_solution(n: Int, k: Int) -> List(Int) {
  let boss = [1]
  let sums =
    working_actors.spawn_workers(1, boss, fn(_x) {
      let step = 10
      let units = batch(n, step)
      let cnts =
        working_actors.spawn_workers(list.length(units), units, fn(start) {
          let end = start + step - 1
          let range = list.range(start, end)
          let sols = list.filter(range, fn(x) { actor_function(x, k) })
          let cnt = list.length(sols)
          list.each(sols, fn(x) { io.println(int.to_string(x)) })
          cnt
        })
      let total = list.fold(cnts, 0, fn(acc, x) { acc + x })
      total
    })
  sums
}

fn actor_function(s: Int, k: Int) {
  let sumsquares =
    list.range(s, s + k - 1)
    |> list.map(fn(x) { x * x })
    |> list.fold(0, fn(acc, x) { acc + x })
  let root = int.square_root(sumsquares) |> result.unwrap(0.0) |> float.floor()
  let result = {
    root *. root == int.to_float(sumsquares)
  }
  result
}
