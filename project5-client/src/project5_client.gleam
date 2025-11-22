import gleam/erlang/process
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import io_models
import logging
import requests

pub fn main() -> Nil {
  logging.set_level(logging.Info)
  logging.log(logging.Info, "Starting requests now.")
  let user1_email = "kochharm@ufl.edu"
  let user2_email = "adhawale@ufl.edu"
  let user3_email = "jatin.salve@ufl.edu"
  let users = ["kochharm@ufl.edu", "adhawale@ufl.edu", "jatin.salve@ufl.edu"]
  let subreddit1_name = "University of Florida"
  let posts = ["COP5615", "COT5405", "COT5615"]
  let random_comments = [
    "Fun class",
    "Amazing teacher",
    "Interesting Projects",
    "Learned a lot",
    "Mandatory Attendance",
    "Great coursework",
    "Syllabus up to date",
    "Large class strength",
  ]

  requests.create_user(user1_email, "kochharm")
  requests.create_user(user2_email, "adhawale")
  requests.create_user(user3_email, "jsalve")

  let assert Ok(sampled_user) = list.sample(users, 1) |> list.first

  let subreddit_id = requests.create_subreddit(subreddit1_name, user1_email)

  let _ = case subreddit_id {
    Some(subreddit_id) -> {
      requests.handle_subreddit_membership(
        subreddit_id,
        user2_email,
        requests.Join,
      )
      requests.handle_subreddit_membership(
        subreddit_id,
        user3_email,
        requests.Join,
      )
      let post_ids =
        list.map(posts, fn(post) {
          requests.create_post(subreddit_id, post, user1_email)
        })
      let filtered_post_ids =
        list.filter_map(post_ids, fn(post_id) {
          let status = case post_id {
            Some(post_id) -> Ok(#(post_id, None))
            None -> Error(Nil)
          }
        })

      let comment_ids =
        list.map(filtered_post_ids, fn(post_id) {
          let assert Ok(comment) = list.sample(random_comments, 1) |> list.first
          let assert Ok(sampled_user) = list.sample(users, 1) |> list.first
          requests.create_comment(post_id, None, comment, sampled_user)
        })

      let post_comment_ids =
        list.map2(
          filtered_post_ids,
          comment_ids,
          fn(filtered_post_id, comment_id) {
            let status = case comment_id {
              Some(comment_id) -> Ok(#(filtered_post_id, comment_id))
              None -> Error(Nil)
            }
          },
        )

      let filtered_post_comment_ids =
        list.filter_map(post_comment_ids, fn(post_comment_id) {
          case post_comment_id {
            Ok(post_comment_id) -> Ok(post_comment_id)
            _ -> Error(Nil)
          }
        })

      list.map(filtered_post_comment_ids, fn(post_comment_id) {
        let assert Ok(comment) = list.sample(random_comments, 1) |> list.first
        requests.create_comment(
          post_comment_id.0,
          Some(post_comment_id.1),
          comment,
          sampled_user,
        )
      })

      Nil
    }
    _ -> {
      logging.log(logging.Info, "Failed creating subreddit.")
    }
  }

  process.sleep(5000)
  Nil
}
