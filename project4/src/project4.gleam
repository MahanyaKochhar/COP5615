import clients.{handle_request}
import engine.{handle_action}
import gleam/dict
import gleam/erlang/process
import gleam/io
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import models.{Directory}

pub fn simulate_user(client_subject: process.Subject(clients.Request)) {
  let email = "kochharm@ufl.edu"
  let password = "kochharm"
  let name = "University of Florida"
  let email =
    actor.call(client_subject, 1000, clients.Register(email, password, _))

  case email {
    Ok(email) -> {
      let subreddit_uuid =
        actor.call(client_subject, 1000, clients.CreateSubReddit(name, _))
      case subreddit_uuid {
        Ok(subreddit_uuid) -> {
          let post_uuid =
            actor.call(client_subject, 1000, clients.CreatePost(
              subreddit_uuid,
              "Distributed Operating System Principles",
              _,
            ))
          case post_uuid {
            Ok(post_uuid) -> {
              let comment_uuid =
                actor.call(client_subject, 1000, clients.CreateComment(
                  post_uuid,
                  None,
                  "Reddit Engine is a fun project.",
                  _,
                ))
            }
            _ -> {
              todo
            }
          }
        }
        _ -> {
          todo
        }
      }
    }
    _ -> {
      todo
    }
  }
}

pub fn main() -> Nil {
  let base_directory =
    Directory(dict.new(), dict.new(), dict.new(), dict.new(), dict.new())
  let assert Ok(engine_actor) =
    actor.new(base_directory) |> actor.on_message(handle_action) |> actor.start
  let engine_subject = engine_actor.data

  let assert Ok(client_actor) =
    actor.new(#(engine_subject, ""))
    |> actor.on_message(handle_request)
    |> actor.start
  let client_subject = client_actor.data
  Nil
}
