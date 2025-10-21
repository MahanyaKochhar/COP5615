// ranking.gleam - Feed ranking algorithms

import gleam/list
import model.{type Comment, type FeedKind, type Post, Hot, New, Top}

// Sort posts by ranking algorithm
pub fn sort_posts(posts: List(Post), kind: FeedKind) -> List(Post) {
  case kind {
    New -> sort_by_new(posts)
    Top -> sort_by_top(posts)
    Hot -> sort_by_hot(posts)
  }
}

// Sort by newest first
fn sort_by_new(posts: List(Post)) -> List(Post) {
  list.sort(posts, fn(a, b) {
    case a.created_at > b.created_at {
      True -> gleam.order.Gt
      False ->
        case a.created_at < b.created_at {
          True -> gleam.order.Lt
          False -> gleam.order.Eq
        }
    }
  })
}

// Sort by highest score
fn sort_by_top(posts: List(Post)) -> List(Post) {
  list.sort(posts, fn(a, b) {
    case a.score > b.score {
      True -> gleam.order.Gt
      False ->
        case a.score < b.score {
          True -> gleam.order.Lt
          False -> gleam.order.Eq
        }
    }
  })
}

// Sort by hot score (Reddit algorithm)
fn sort_by_hot(posts: List(Post)) -> List(Post) {
  list.sort(posts, fn(a, b) {
    let hot_a = calculate_hot_score(a)
    let hot_b = calculate_hot_score(b)

    case hot_a >. hot_b {
      True -> gleam.order.Gt
      False ->
        case hot_a <. hot_b {
          True -> gleam.order.Lt
          False -> gleam.order.Eq
        }
    }
  })
}

// Calculate hot score for a post
// Formula: score / (hours_since_creation + 2)^1.5
pub fn calculate_hot_score(post: Post) -> Float {
  let current_time = get_current_timestamp()
  let age_seconds = current_time - post.created_at
  let age_hours = int_to_float(age_seconds) /. 3600.0

  let score_float = int_to_float(post.score)
  let denominator = power(age_hours +. 2.0, 1.5)

  score_float /. denominator
}

// Sort comments by score (for nested display)
pub fn sort_comments(comments: List(Comment)) -> List(Comment) {
  list.sort(comments, fn(a, b) {
    case a.score > b.score {
      True -> gleam.order.Gt
      False ->
        case a.score < b.score {
          True -> gleam.order.Lt
          False -> gleam.order.Eq
        }
    }
  })
}

// Build comment tree structure for hierarchical display
pub type CommentTree {
  CommentNode(comment: Comment, children: List(CommentTree))
}

pub fn build_comment_tree(
  comments: List(Comment),
  parent_id: option.Option(Int),
) -> List(CommentTree) {
  // Find all comments with the given parent
  let matching_comments =
    list.filter(comments, fn(c) { c.parent_id == parent_id })

  // Recursively build tree for each comment
  list.map(matching_comments, fn(comment) {
    let children = build_comment_tree(comments, option.Some(comment.id))
    CommentNode(comment: comment, children: children)
  })
}

// Helper functions

fn get_current_timestamp() -> Int {
  // In real implementation, use BEAM timestamp
  0
}

fn int_to_float(i: Int) -> Float {
  case i {
    0 -> 0.0
    _ -> {
      let is_negative = i < 0
      let abs_val = case is_negative {
        True -> -i
        False -> i
      }
      let result = convert_positive_int(abs_val)
      case is_negative {
        True -> 0.0 -. result
        False -> result
      }
    }
  }
}

fn convert_positive_int(i: Int) -> Float {
  case i {
    0 -> 0.0
    _ -> {
      let digit = i % 10
      let rest = i / 10
      convert_positive_int(rest) *. 10.0 +. digit_to_float(digit)
    }
  }
}

fn digit_to_float(d: Int) -> Float {
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

fn power(base: Float, exp: Float) -> Float {
  // For exp = 1.5, calculate base^1.5 = base * sqrt(base)
  case exp {
    1.5 -> base *. sqrt(base)
    _ -> base
  }
}

fn sqrt(x: Float) -> Float {
  // Newton's method
  case x <. 0.0 {
    True -> 0.0
    False -> sqrt_iter(x, x /. 2.0, 0)
  }
}

fn sqrt_iter(x: Float, guess: Float, count: Int) -> Float {
  case count > 10 {
    True -> guess
    False -> {
      let next = { guess +. { x /. guess } } /. 2.0
      let diff = abs_float(guess -. next)
      case diff <. 0.0001 {
        True -> next
        False -> sqrt_iter(x, next, count + 1)
      }
    }
  }
}

fn abs_float(x: Float) -> Float {
  case x <. 0.0 {
    True -> 0.0 -. x
    False -> x
  }
}
