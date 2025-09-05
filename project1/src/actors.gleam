import gleam/erlang/process
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/otp/actor
import gleam/result

const wait_ms = 500_000

pub fn work(n: Int, k: Int, step: Int) -> Bool {
  let assert Ok(boss) =
    actor.new(#(0, [])) |> actor.on_message(handle_boss_message) |> actor.start
  let subject = boss.data
  actor.send(subject, Split(n, k, step, subject))
  let _ = actor.call(subject, wait_ms, Get)
  True
}

type BossMessage {
  Shutdown
  Split(Int, Int, Int, process.Subject(BossMessage))
  Done(List(Int))
  Get(process.Subject(Result(Bool, Nil)))
}

type WorkerMessage {
  Solve(Int, Int, Int, process.Subject(BossMessage))
}

fn batch(n: Int, step: Int) -> List(Int) {
  let units =
    list.range(1, n)
    |> list.filter(fn(x) { { x - 1 } % step == 0 })
  units
}

fn check_squares(s: Int, k: Int) -> Bool {
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

fn get_default_step(n: Int) -> Int {
  let result = int.square_root(n) |> result.unwrap(1.0) |> float.round
  result
}

fn handle_boss_message(
  state: #(Int, List(process.Subject(Result(Bool, Nil)))),
  message: BossMessage,
) -> actor.Next(#(Int, List(process.Subject(Result(Bool, Nil)))), BossMessage) {
  case message {
    Shutdown -> actor.stop()
    Split(n, k, step, boss) -> {
      let step = case step > 0 {
        True -> step
        False -> get_default_step(n)
      }
      let units = batch(n, step)
      list.map(units, fn(start) {
        let end = start + step - 1
        let assert Ok(worker) =
          actor.new([])
          |> actor.on_message(handle_worker_message)
          |> actor.start
        let subject = worker.data
        actor.send(subject, Solve(start, end, k, boss))
      })
      actor.continue(#(list.length(units), state.1))
    }
    Done(result) -> {
      list.each(result, fn(x) { io.println(int.to_string(x)) })
      let new_cnt = state.0 - 1
      case state.1 {
        [a, ..] -> {
          case new_cnt <= 0 {
            True -> actor.send(a, Ok(True))
            False -> Nil
          }
        }
        _ -> Nil
      }
      actor.continue(#(new_cnt, state.1))
    }

    Get(client) -> {
      case state.0 > 0 {
        True -> Nil
        False -> actor.send(client, Ok(True))
      }
      actor.continue(#(state.0, [client]))
    }
  }
}

fn handle_worker_message(
  _ls: List(Int),
  message: WorkerMessage,
) -> actor.Next(List(Int), WorkerMessage) {
  case message {
    Solve(start, end, k, boss) -> {
      let range = list.range(start, end)
      let sols = list.filter(range, fn(s) { check_squares(s, k) })
      actor.send(boss, Done(sols))
      actor.continue(sols)
    }
  }
}
