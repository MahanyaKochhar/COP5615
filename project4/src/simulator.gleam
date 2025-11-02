import clients
import engine
import gleam/dict
import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/actor

const call_milliseconds = 5000

pub fn simulate_root_user(client_subject: process.Subject(clients.Request)) {
  let dict = dict.new()
  let email = "kochharm@ufl.edu"
  let password = "kochharm"
  let subreddit_name = "University of Florida"
  let post_name = "Distributed Operating System Principles"
  let comment_name = "Deadline for Project 2 is Nov 2 midnight."
  let child_comment_name = "Please use Gleam and the actor model only."
  let email =
    actor.call(client_subject, call_milliseconds, clients.Register(
      email,
      password,
      _,
    ))

  let updated_dict = case email {
    Ok(email) -> {
      let subreddit_uuid =
        actor.call(client_subject, call_milliseconds, clients.CreateSubReddit(
          subreddit_name,
          _,
        ))
      case subreddit_uuid {
        Ok(subreddit_uuid) -> {
          let updated_dict = dict.insert(dict, "subreddit_uuid", subreddit_uuid)
          let post_uuid =
            actor.call(client_subject, call_milliseconds, clients.CreatePost(
              subreddit_uuid,
              post_name,
              _,
            ))
          let updated_dict = case post_uuid {
            Ok(post_uuid) -> {
              let updated_dict =
                dict.insert(updated_dict, "post_uuid", post_uuid)
              let comment_uuid =
                actor.call(
                  client_subject,
                  call_milliseconds,
                  clients.CreateComment(post_uuid, None, comment_name, _),
                )
              let updated_dict = case comment_uuid {
                Ok(comment_uuid) -> {
                  let updated_dict =
                    dict.insert(updated_dict, "comment_uuid", comment_uuid)
                  let child_comment_uuid =
                    actor.call(
                      client_subject,
                      call_milliseconds,
                      clients.CreateComment(
                        post_uuid,
                        Some(comment_uuid),
                        child_comment_name,
                        _,
                      ),
                    )
                  let updated_dict = case child_comment_uuid {
                    Ok(child_comment_uuid) -> {
                      dict.insert(
                        updated_dict,
                        "child_comment_uuid",
                        child_comment_uuid,
                      )
                    }
                    _ -> updated_dict
                  }
                }
                _ -> updated_dict
              }
              updated_dict
            }
            _ -> {
              io.println("Post not created.")
              dict
            }
          }
          updated_dict
        }
        _ -> {
          io.println("Subreddit not created.")
          dict
        }
      }
    }
    _ -> {
      io.println("User not created.")
      dict
    }
  }
  updated_dict
}

pub fn create_subreddits(
  user_subjects: List(process.Subject(clients.Request)),
  subreddits: Int,
) {
  let subreddit_names =
    list.map(list.range(1, subreddits), fn(no) {
      let str = "Simulated Subreddit " <> int.to_string(no)
    })

  let subreddit_uuids =
    list.map2(user_subjects, subreddit_names, fn(user_subject, subreddit_name) {
      let assert Ok(subreddit_uuid) =
        actor.call(user_subject, call_milliseconds, clients.CreateSubReddit(
          subreddit_name,
          _,
        ))
      subreddit_uuid
    })
  subreddit_uuids
}

pub fn simulate_users(
  engine_subject: process.Subject(engine.Action),
  inputs: #(Int, Int),
) {
  let user_subjects =
    list.map(list.range(1, inputs.0), fn(no) {
      let assert Ok(user_actor) =
        actor.new(#(engine_subject, ""))
        |> actor.on_message(clients.handle_request)
        |> actor.start
      let email = "Simulated User " <> int.to_string(no) <> " Email"
      let password = "Simulated User " <> int.to_string(no) <> " Password"
      let user_subject = user_actor.data
      let email =
        actor.call(user_subject, call_milliseconds, clients.Register(
          email,
          password,
          _,
        ))
      user_subject
    })
  user_subjects
}
