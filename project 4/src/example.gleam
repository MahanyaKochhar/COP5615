// example.gleam - Example usage of the Reddit engine

import api
import engine
import gleam/io
import gleam/option.{None, Some}
import model.{
  CommentCreated, Error, FeedResult, Hot, New, PostCreated, SubredditCreated,
  UserCreated,
}

pub fn main() {
  io.println("=== Reddit Engine Example ===\n")

  // Initialize engine
  let state = engine.new()
  io.println("✓ Engine initialized")

  // Create users
  let #(state, resp1) = api.execute(state, api.register_user("alice"))
  let alice_id = case resp1 {
    UserCreated(user) -> {
      io.println("✓ User created: " <> user.username)
      user.id
    }
    _ -> panic as "Failed to create user"
  }

  let #(state, resp2) = api.execute(state, api.register_user("bob"))
  let bob_id = case resp2 {
    UserCreated(user) -> {
      io.println("✓ User created: " <> user.username)
      user.id
    }
    _ -> panic as "Failed to create user"
  }

  let #(state, _) = api.execute(state, api.register_user("charlie"))
  io.println("✓ User created: charlie\n")

  // Create subreddit
  let #(state, resp3) =
    api.execute(state, api.create_subreddit("gleam", alice_id))
  let subreddit_id = case resp3 {
    SubredditCreated(subreddit) -> {
      io.println("✓ Subreddit created: r/" <> subreddit.name)
      subreddit.id
    }
    _ -> panic as "Failed to create subreddit"
  }

  // Users join subreddit
  let #(state, _) =
    api.execute(state, api.join_subreddit(alice_id, subreddit_id))
  let #(state, _) = api.execute(state, api.join_subreddit(bob_id, subreddit_id))
  io.println("✓ Users joined subreddit\n")

  // Create posts
  let #(state, resp4) =
    api.execute(
      state,
      api.create_post(
        alice_id,
        subreddit_id,
        "Welcome to r/gleam!",
        "Let's discuss the Gleam programming language",
      ),
    )

  let post1_id = case resp4 {
    PostCreated(post) -> {
      io.println("✓ Post created: " <> post.title)
      post.id
    }
    _ -> panic as "Failed to create post"
  }

  let #(state, resp5) =
    api.execute(
      state,
      api.create_post(
        bob_id,
        subreddit_id,
        "Gleam is awesome!",
        "I just learned about pattern matching",
      ),
    )

  let post2_id = case resp5 {
    PostCreated(post) -> {
      io.println("✓ Post created: " <> post.title)
      post.id
    }
    _ -> panic as "Failed to create post"
  }

  io.println("")

  // Add comments
  let #(state, resp6) =
    api.execute(
      state,
      api.create_comment(bob_id, post1_id, None, "Great idea! I'm excited"),
    )

  let comment1_id = case resp6 {
    CommentCreated(comment) -> {
      io.println("✓ Comment added to post 1")
      comment.id
    }
    _ -> panic as "Failed to create comment"
  }

  let #(state, _) =
    api.execute(
      state,
      api.create_comment(
        alice_id,
        post1_id,
        Some(comment1_id),
        "Thanks! Let's grow this community",
      ),
    )
  io.println("✓ Reply added to comment\n")

  // Vote on posts
  let #(state, _) = api.execute(state, api.upvote_post(bob_id, post1_id))
  let #(state, _) = api.execute(state, api.upvote_post(alice_id, post2_id))
  let #(state, _) = api.execute(state, api.upvote_post(bob_id, post2_id))
  io.println("✓ Votes cast on posts\n")

  // Get feed (new posts)
  let #(state, resp7) =
    api.execute(state, api.get_feed(None, Some(subreddit_id), New, 10))

  case resp7 {
    FeedResult(posts) -> {
      io.println("=== Feed (New) ===")
      list.each(posts, fn(post) {
        io.println(
          "- "
          <> post.title
          <> " (score: "
          <> int_to_string(post.score)
          <> ", comments: "
          <> int_to_string(post.comment_count)
          <> ")",
        )
      })
      io.println("")
    }
    _ -> io.println("Failed to get feed")
  }

  // Get feed (hot posts)
  let #(state, resp8) =
    api.execute(state, api.get_feed(None, Some(subreddit_id), Hot, 10))

  case resp8 {
    FeedResult(posts) -> {
      io.println("=== Feed (Hot) ===")
      list.each(posts, fn(post) {
        io.println(
          "- " <> post.title <> " (score: " <> int_to_string(post.score) <> ")",
        )
      })
      io.println("")
    }
    _ -> io.println("Failed to get feed")
  }

  // Get metrics
  let #(state, resp9) = api.execute(state, api.get_metrics())

  case resp9 {
    model.MetricsResult(metrics) -> {
      io.println("=== Engine Metrics ===")
      io.println("Total users: " <> int_to_string(metrics.total_users))
      io.println(
        "Total subreddits: " <> int_to_string(metrics.total_subreddits),
      )
      io.println("Total posts: " <> int_to_string(metrics.total_posts))
      io.println("Total comments: " <> int_to_string(metrics.total_comments))
      io.println("Total votes: " <> int_to_string(metrics.total_votes))
    }
    _ -> io.println("Failed to get metrics")
  }

  io.println("\n✓ Example completed successfully!")

  state
}

// Demonstrate batch operations
pub fn batch_example() {
  io.println("\n=== Batch Operations Example ===\n")

  let state = engine.new()

  // Create multiple operations at once
  let messages = [
    api.register_user("user1"),
    api.register_user("user2"),
    api.register_user("user3"),
    api.create_subreddit("gaming", 1),
    api.create_subreddit("music", 2),
  ]

  let #(new_state, responses) = api.execute_batch(state, messages)

  io.println(
    "Executed " <> int_to_string(list.length(messages)) <> " operations",
  )
  io.println(
    "Successful operations: " <> int_to_string(count_success(responses)),
  )

  new_state
}

fn count_success(responses: List(model.EngineResponse)) -> Int {
  list.fold(responses, 0, fn(acc, resp) {
    case resp {
      Error(_) -> acc
      _ -> acc + 1
    }
  })
}

// Demonstrate repost detection
pub fn repost_example() {
  io.println("\n=== Repost Detection Example ===\n")

  let state = engine.new()

  // Create user and subreddit
  let #(state, resp1) = api.execute(state, api.register_user("alice"))
  let user_id = case resp1 {
    UserCreated(user) -> user.id
    _ -> panic as "Failed"
  }

  let #(state, resp2) =
    api.execute(state, api.create_subreddit("test", user_id))
  let sub_id = case resp2 {
    SubredditCreated(sub) -> sub.id
    _ -> panic as "Failed"
  }

  let #(state, _) = api.execute(state, api.join_subreddit(user_id, sub_id))

  // Create original post
  let #(state, resp3) =
    api.execute(
      state,
      api.create_post(user_id, sub_id, "Original Post", "This is the content"),
    )

  let original_id = case resp3 {
    PostCreated(post) -> {
      io.println(
        "✓ Original post created (ID: " <> int_to_string(post.id) <> ")",
      )
      post.id
    }
    _ -> panic as "Failed"
  }

  // Try to create duplicate post
  let #(state, resp4) =
    api.execute(
      state,
      api.create_post(user_id, sub_id, "Original Post", "This is the content"),
    )

  case resp4 {
    PostCreated(post) -> {
      case post.repost_of {
        Some(repost_id) ->
          io.println(
            "✓ Repost detected! New post ID "
            <> int_to_string(post.id)
            <> " is a repost of "
            <> int_to_string(repost_id),
          )
        None -> io.println("✗ Repost not detected")
      }
    }
    _ -> io.println("Failed to create post")
  }

  state
}

// Demonstrate comment threading
pub fn comment_thread_example() {
  io.println("\n=== Comment Threading Example ===\n")

  let state = engine.new()

  // Setup
  let #(state, resp1) = api.execute(state, api.register_user("alice"))
  let alice_id = case resp1 {
    UserCreated(user) -> user.id
    _ -> panic as "Failed"
  }

  let #(state, resp2) = api.execute(state, api.register_user("bob"))
  let bob_id = case resp2 {
    UserCreated(user) -> user.id
    _ -> panic as "Failed"
  }

  let #(state, resp3) =
    api.execute(state, api.create_subreddit("discussion", alice_id))
  let sub_id = case resp3 {
    SubredditCreated(sub) -> sub.id
    _ -> panic as "Failed"
  }

  let #(state, _) = api.execute(state, api.join_subreddit(alice_id, sub_id))
  let #(state, _) = api.execute(state, api.join_subreddit(bob_id, sub_id))

  let #(state, resp4) =
    api.execute(
      state,
      api.create_post(alice_id, sub_id, "What do you think?", "Discuss"),
    )

  let post_id = case resp4 {
    PostCreated(post) -> post.id
    _ -> panic as "Failed"
  }

  // Create comment thread
  let #(state, resp5) =
    api.execute(
      state,
      api.create_comment(bob_id, post_id, None, "Top level comment"),
    )

  let comment1_id = case resp5 {
    CommentCreated(comment) -> comment.id
    _ -> panic as "Failed"
  }

  let #(state, resp6) =
    api.execute(
      state,
      api.create_comment(
        alice_id,
        post_id,
        Some(comment1_id),
        "Reply to top level",
      ),
    )

  let comment2_id = case resp6 {
    CommentCreated(comment) -> comment.id
    _ -> panic as "Failed"
  }

  let #(state, _) =
    api.execute(
      state,
      api.create_comment(bob_id, post_id, Some(comment2_id), "Nested reply"),
    )

  io.println("✓ Created comment thread with 3 levels")

  // Get all comments for post
  let #(state, resp7) = api.execute(state, api.get_comments(post_id))

  case resp7 {
    model.CommentsResult(comments) -> {
      io.println(
        "✓ Retrieved "
        <> int_to_string(list.length(comments))
        <> " comments for the post",
      )
    }
    _ -> io.println("Failed to get comments")
  }

  state
}

// Helper function to convert int to string
fn int_to_string(i: Int) -> String {
  case i {
    0 -> "0"
    _ -> {
      let is_neg = i < 0
      let abs_i = case is_neg {
        True -> -i
        False -> i
      }
      let result = int_to_string_helper(abs_i, "")
      case is_neg {
        True -> "-" <> result
        False -> result
      }
    }
  }
}

fn int_to_string_helper(i: Int, acc: String) -> String {
  case i {
    0 -> acc
    _ -> {
      let digit = i % 10
      let rest = i / 10
      int_to_string_helper(rest, digit_to_char(digit) <> acc)
    }
  }
}

fn digit_to_char(d: Int) -> String {
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
