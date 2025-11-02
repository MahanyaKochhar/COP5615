import argv
import clients.{handle_request}
import engine.{handle_action}
import gleam/dict
import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/result
import models.{Directory}
import simulator

pub fn main() -> Nil {
  let inputs = case argv.load().arguments {
    [num_users, num_subreddits] -> {
      let users = int.base_parse(num_users, 10) |> result.unwrap(10)
      let subreddits = int.base_parse(num_subreddits, 10) |> result.unwrap(5)
      #(users, subreddits)
    }
    _ -> #(10, 5)
  }

  let base_directory =
    Directory(
      dict.new(),
      dict.new(),
      dict.new(),
      dict.new(),
      dict.new(),
      dict.new(),
    )
  let assert Ok(engine_actor) =
    actor.new(base_directory) |> actor.on_message(handle_action) |> actor.start
  let engine_subject = engine_actor.data

  let assert Ok(root_actor) =
    actor.new(#(engine_subject, ""))
    |> actor.on_message(handle_request)
    |> actor.start
  let root_subject = root_actor.data

  let updated_dict = simulator.simulate_root_user(root_subject)
  let user_subjects = simulator.simulate_users(engine_subject, inputs)
  simulator.create_subreddits(user_subjects, inputs.1)
  actor.send(engine_subject, engine.GetState)
  process.sleep(5000)
  Nil
}
