// utils.gleam - Utility functions for the engine

import gleam/dict.{type Dict}
import gleam/list
import gleam/string
import model.{type Post, type User}

// Validation functions

pub fn is_valid_username(username: String) -> Bool {
  let length = string.length(username)
  length >= 3 && length <= 20 && is_alphanumeric(username)
}

pub fn is_valid_subreddit_name(name: String) -> Bool {
  let length = string.length(name)
  length >= 3 && length <= 21 && is_alphanumeric(name)
}

pub fn is_valid_post_title(title: String) -> Bool {
  let length = string.length(title)
  length > 0 && length <= 300
}

pub fn is_valid_post_body(body: String) -> Bool {
  string.length(body) <= 40_000
}

pub fn is_valid_comment_body(body: String) -> Bool {
  let length = string.length(body)
  length > 0 && length <= 10_000
}

fn is_alphanumeric(s: String) -> Bool {
  string.to_graphemes(s)
  |> list.all(fn(c) {
    { c >= "a" && c <= "z" }
    || { c >= "A" && c <= "Z" }
    || { c >= "0" && c <= "9" }
    || c == "_"
  })
}

// Statistics functions

pub fn calculate_user_post_count(posts: Dict(Int, Post), user_id: Int) -> Int {
  dict.values(posts)
  |> list.filter(fn(post) { post.author_id == user_id })
  |> list.length
}

pub fn calculate_total_karma(users: Dict(Int, User)) -> Int {
  dict.values(users)
  |> list.fold(0, fn(acc, user) { acc + user.karma })
}

pub fn get_top_users_by_karma(users: Dict(Int, User), limit: Int) -> List(User) {
  dict.values(users)
  |> list.sort(fn(a, b) {
    case a.karma > b.karma {
      True -> gleam.order.Gt
      False ->
        case a.karma < b.karma {
          True -> gleam.order.Lt
          False -> gleam.order.Eq
        }
    }
  })
  |> list.take(limit)
}

pub fn get_top_posts(posts: Dict(Int, Post), limit: Int) -> List(Post) {
  dict.values(posts)
  |> list.sort(fn(a, b) {
    case a.score > b.score {
      True -> gleam.order.Gt
      False ->
        case a.score < b.score {
          True -> gleam.order.Lt
          False -> gleam.order.Eq
        }
    }
  })
  |> list.take(limit)
}

// Content hashing for repost detection

pub fn hash_post_content(title: String, body: String) -> String {
  // Simple concatenation hash
  // In production, use proper cryptographic hash
  normalize_text(title) <> "|" <> normalize_text(body)
}

fn normalize_text(text: String) -> String {
  // Normalize text for comparison
  string.lowercase(text)
  |> string.trim
}

// Time utilities

pub fn get_timestamp() -> Int {
  // Placeholder - in real implementation use BEAM time functions
  // erlang:system_time(second)
  0
}

pub fn hours_since(timestamp: Int) -> Float {
  let current = get_timestamp()
  let diff = current - timestamp
  int_to_float(diff) /. 3600.0
}

pub fn days_since(timestamp: Int) -> Float {
  hours_since(timestamp) /. 24.0
}

fn int_to_float(i: Int) -> Float {
  case i {
    0 -> 0.0
    _ -> {
      let is_neg = i < 0
      let abs_i = case is_neg {
        True -> -i
        False -> i
      }
      let result = to_float_helper(abs_i, 0.0)
      case is_neg {
        True -> 0.0 -. result
        False -> result
      }
    }
  }
}

fn to_float_helper(i: Int, acc: Float) -> Float {
  case i {
    0 -> acc
    _ -> {
      let digit = i % 10
      let rest = i / 10
      to_float_helper(rest, acc *. 10.0 +. int_digit_to_float(digit))
    }
  }
}

fn int_digit_to_float(d: Int) -> Float {
  case d {
    0 -> 0.0
    1 -> 1.0
    2 -> 2.0
    3 -> 3.0
    4 -> 4.0
    5 -> 5.0
    6 -> 6.0
    7 -> 7.0
    8 -> 8.0
    9 -> 9.0
    _ -> 0.0
  }
}

// ID generation helpers

pub fn generate_id_string(id: Int) -> String {
  "id_" <> int_to_string(id)
}

fn int_to_string(i: Int) -> String {
  case i {
    0 -> "0"
    _ -> {
      let is_neg = i < 0
      let abs_i = case is_neg {
        True -> -i
        False -> i
      }
      let digits = to_string_helper(abs_i, "")
      case is_neg {
        True -> "-" <> digits
        False -> digits
      }
    }
  }
}

fn to_string_helper(i: Int, acc: String) -> String {
  case i {
    0 -> acc
    _ -> {
      let digit = i % 10
      let rest = i / 10
      to_string_helper(rest, digit_to_string(digit) <> acc)
    }
  }
}

fn digit_to_string(d: Int) -> String {
  case d {
    0 -> "0"
    1 -> "1"
    2 -> "2"
    3 -> "3"
    4 -> "4"
    5 -> "5"
    6 -> "6"
    7 -> "7"
    8 -> "8"
    9 -> "9"
    _ -> "0"
  }
}
