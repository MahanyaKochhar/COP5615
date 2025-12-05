import gleam/bit_array
import gleam/crypto
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
import prng/random
import requests
import rsa_keys

pub fn main() -> Nil {
  logging.set_level(logging.Info)
  logging.log(logging.Info, "Starting requests now.")
  let user1_email = "kochharm@ufl.edu"
  let #(pubkey, privkey) = rsa_keys.generate_rsa_keys()
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

  requests.create_user(user1_email, "kochharm", Some(pubkey))
  requests.create_user(user2_email, "adhawale", None)
  requests.create_user(user3_email, "jsalve", None)

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
      let filtered_post_ids =
        list.filter_map(posts, fn(post) {
          let signature =
            rsa_keys.sign_message_with_pem_string(
              bit_array.from_string(post),
              privkey.pem,
            )
          let final_signature = case signature {
            Ok(signature) -> {
              Some(bit_array.base16_encode(signature))
            }
            _ -> None
          }
          let post_id =
            requests.create_post(
              subreddit_id,
              post,
              final_signature,
              user1_email,
            )
          case post_id {
            Some(post_id) -> Ok(#(post_id, None))
            None -> Error(Nil)
          }
        })
      let filtered_comment_ids =
        list.filter_map(filtered_post_ids, fn(post_comment_id) {
          let assert Ok(comment) = list.sample(random_comments, 1) |> list.first
          let assert Ok(sampled_user) = list.sample(users, 1) |> list.first
          let comment_id =
            requests.create_comment(
              post_comment_id.0,
              None,
              comment,
              sampled_user,
            )
          case comment_id {
            Some(comment_id) -> Ok(#(post_comment_id.0, Some(comment_id)))
            _ -> Error(Nil)
          }
        })

      let more_filtered_comment_ids =
        list.filter_map(filtered_comment_ids, fn(post_comment_id) {
          let assert Ok(comment) = list.sample(random_comments, 1) |> list.first
          let comment_id =
            requests.create_comment(
              post_comment_id.0,
              post_comment_id.1,
              comment,
              sampled_user,
            )
          case comment_id {
            Some(comment_id) -> Ok(#(post_comment_id.0, Some(comment_id)))
            _ -> Error(Nil)
          }
        })

      let all_posts_comments =
        list.append(filtered_post_ids, filtered_comment_ids)
        |> list.append(more_filtered_comment_ids)

      let generator = random.int(0, 1)
      list.range(1, 100)
      |> list.map(fn(_no) {
        let assert Ok(sampled_user) = list.sample(users, 1) |> list.first
        let assert Ok(post_comment) =
          list.sample(all_posts_comments, 1) |> list.first
        let up = random.random_sample(generator)
        let down = 1 - up
        requests.vote(post_comment.0, post_comment.1, up, down, sampled_user)
      })
      requests.user(user1_email)
      requests.user(user2_email)
      requests.user(user3_email)
      requests.feed(user1_email, Some(user1_email))
      requests.feed(user2_email,Some(user1_email))
      requests.handle_subreddit_membership(
        subreddit_id,
        user3_email,
        requests.Leave,
      )
      requests.feed(user3_email, None)
      process.sleep(500_000)

      requests.user_inbox(user1_email)
      requests.user_inbox(user3_email)
      Nil
    }
    _ -> {
      logging.log(logging.Info, "Failed creating subreddit.")
    }
  }

  process.sleep(5000)
  Nil
}
