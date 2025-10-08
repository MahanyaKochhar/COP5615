import gleam/int
import gleam/io

pub fn timestamp_loop_until(stop_condition: fn(Int) -> Bool) -> Nil {
  loop_with_condition(stop_condition)
}

pub fn main() -> Nil {
  // Run 10 times by default - change this number as needed
  loop_count(0, 10)
}

pub fn timestamp_loop_count(max_iterations: Int) -> Nil {
  loop_count(0, max_iterations)
}

fn loop_with_condition(stop_condition: fn(Int) -> Bool) -> Nil {
  let timestamp = get_timestamp()

  io.println("Timestamp: " <> int.to_string(timestamp))

  // Check if we should stop
  case stop_condition(timestamp) {
    True -> {
      io.println("Stop condition met. Exiting loop.")
      Nil
    }
    False -> {
      sleep(3000)
      loop_with_condition(stop_condition)
    }
  }
}

fn loop_count(current: Int, max: Int) -> Nil {
  case current >= max {
    True -> {
      io.println(
        "Reached " <> int.to_string(max) <> " iterations. Exiting loop.",
      )
      Nil
    }
    False -> {
      let timestamp = get_timestamp()
      io.println(
        "Iteration "
        <> int.to_string(current + 1)
        <> " - Timestamp: "
        <> int.to_string(timestamp),
      )
      sleep(3000)
      loop_count(current + 1, max)
    }
  }
}

fn get_timestamp() -> Int {
  erlang_system_time_millisecond()
}

@external(erlang, "erlang", "system_time")
fn erlang_system_time_millisecond() -> Int

@external(erlang, "timer", "sleep")
fn sleep(milliseconds: Int) -> Nil
