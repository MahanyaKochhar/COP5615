import clients.{handle_request}
import engine.{handle_action}
import gleam/dict
import gleam/erlang/process
import gleam/io
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import models.{Directory}

const call_milliseconds = 5000

pub fn simulate_user(client_subject: process.Subject(clients.Request)) {
  let email = "kochharm@ufl.edu"
  let password = "kochharm"
  let name = "University of Florida"
  let email =
    actor.call(client_subject, call_milliseconds, clients.Register(
      email,
      password,
      _,
    ))

  case email {
    Ok(email) -> {
      let subreddit_uuid =
        actor.call(client_subject, call_milliseconds, clients.CreateSubReddit(
          name,
          _,
        ))
      case subreddit_uuid {
        Ok(subreddit_uuid) -> {
          let post_uuid =
            actor.call(client_subject, call_milliseconds, clients.CreatePost(
              subreddit_uuid,
              "Distributed Operating System Principles",
              _,
            ))
          case post_uuid {
            Ok(post_uuid) -> {
              let comment_uuid =
                actor.call(
                  client_subject,
                  call_milliseconds,
                  clients.CreateComment(
                    post_uuid,
                    None,
                    "Reddit Engine is a fun project.",
                    _,
                  ),
                )
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
  io.println("Initial State.")
  let assert Ok(engine_actor) =
    actor.new(base_directory) |> actor.on_message(handle_action) |> actor.start
  let engine_subject = engine_actor.data

  let assert Ok(client_actor) =
    actor.new(#(engine_subject, ""))
    |> actor.on_message(handle_request)
    |> actor.start
  let client_subject = client_actor.data
  let email = "kochharm@ufl.edu"
  let password = "kochharm"
  let name = "University of Florida"
  let email1 =
    actor.call(client_subject, call_milliseconds, clients.Register(
      email,
      password,
      _,
    ))
  let assert Ok(subreddit_uuid) =
    actor.call(client_subject, call_milliseconds, clients.CreateSubReddit(
      name,
      _,
    ))
  let email1 =
    actor.call(client_subject, call_milliseconds, clients.Register(
      "jatin",
      password,
      _,
    ))
  actor.call(client_subject, call_milliseconds, clients.JoinSubReddit(
    subreddit_uuid,
    _,
  ))
  let assert Ok(post_uuid) =
    actor.call(client_subject, call_milliseconds, clients.CreatePost(
      subreddit_uuid,
      "DOSP",
      _,
    ))
  actor.call(client_subject, call_milliseconds, clients.CreatePost(
    subreddit_uuid,
    "MIS",
    _,
  ))
  let assert Ok(comment_uuid) =
    actor.call(client_subject, call_milliseconds, clients.CreateComment(
      post_uuid,
      None,
      "Reddit Engine is a fun project.",
      _,
    ))
  let assert Ok(comment_uuid) =
    actor.call(client_subject, call_milliseconds, clients.CreateComment(
      post_uuid,
      Some(comment_uuid),
      "Yes definitely",
      _,
    ))
  let assert Ok(comment_uuid) =
    actor.call(client_subject, call_milliseconds, clients.CreateComment(
      post_uuid,
      Some(comment_uuid),
      "Yes Sir",
      _,
    ))
  actor.call(client_subject, call_milliseconds, clients.Vote(
    post_uuid,
    Some(comment_uuid),
    1,
    0,
    _,
  ))

  let assert Ok(feed) = actor.call(client_subject, 10_000, clients.GetFeed)
  actor.send(engine_subject, engine.GetState)
  process.sleep(5000)
  Nil
}
