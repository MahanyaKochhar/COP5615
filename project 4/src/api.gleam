// api.gleam - Convenient API functions for interacting with the engine

import engine.{type State}
import gleam/list
import gleam/option.{type Option}
import model.{
  type CommentId, type EngineMsg, type EngineResponse, type FeedKind,
  type PostId, type SubredditId, type TargetType, type UserId, CommentTarget,
  CreateComment, CreatePost, CreateSubreddit, GetComments, GetDirectMessages,
  GetFeed, GetMetrics, GetPost, GetSubreddit, GetSubredditByName, GetUser,
  GetUserByName, JoinSubreddit, LeaveSubreddit, PostTarget, RegisterUser,
  SendDirectMessage, VoteMsg,
}

// User operations

pub fn register_user(username: String) -> EngineMsg {
  RegisterUser(username)
}

pub fn get_user(user_id: UserId) -> EngineMsg {
  GetUser(user_id)
}

pub fn get_user_by_username(username: String) -> EngineMsg {
  GetUserByName(username)
}

// Subreddit operations

pub fn create_subreddit(name: String, owner_id: UserId) -> EngineMsg {
  CreateSubreddit(name, owner_id)
}

pub fn get_subreddit(subreddit_id: SubredditId) -> EngineMsg {
  GetSubreddit(subreddit_id)
}

pub fn get_subreddit_by_name(name: String) -> EngineMsg {
  GetSubredditByName(name)
}

pub fn join_subreddit(user_id: UserId, subreddit_id: SubredditId) -> EngineMsg {
  JoinSubreddit(user_id, subreddit_id)
}

pub fn leave_subreddit(user_id: UserId, subreddit_id: SubredditId) -> EngineMsg {
  LeaveSubreddit(user_id, subreddit_id)
}

// Post operations

pub fn create_post(
  author_id: UserId,
  subreddit_id: SubredditId,
  title: String,
  body: String,
) -> EngineMsg {
  CreatePost(author_id, subreddit_id, title, body)
}

pub fn get_post(post_id: PostId) -> EngineMsg {
  GetPost(post_id)
}

pub fn get_feed(
  user_id: Option(UserId),
  subreddit_id: Option(SubredditId),
  kind: FeedKind,
  limit: Int,
) -> EngineMsg {
  GetFeed(user_id, subreddit_id, kind, limit)
}

// Comment operations

pub fn create_comment(
  author_id: UserId,
  post_id: PostId,
  parent_id: Option(CommentId),
  body: String,
) -> EngineMsg {
  CreateComment(author_id, post_id, parent_id, body)
}

pub fn get_comments(post_id: PostId) -> EngineMsg {
  GetComments(post_id)
}

// Voting operations

pub fn upvote_post(user_id: UserId, post_id: PostId) -> EngineMsg {
  VoteMsg(user_id, PostTarget, post_id, 1)
}

pub fn downvote_post(user_id: UserId, post_id: PostId) -> EngineMsg {
  VoteMsg(user_id, PostTarget, post_id, -1)
}

pub fn upvote_comment(user_id: UserId, comment_id: CommentId) -> EngineMsg {
  VoteMsg(user_id, CommentTarget, comment_id, 1)
}

pub fn downvote_comment(user_id: UserId, comment_id: CommentId) -> EngineMsg {
  VoteMsg(user_id, CommentTarget, comment_id, -1)
}

pub fn vote(
  user_id: UserId,
  target_type: TargetType,
  target_id: Int,
  value: Int,
) -> EngineMsg {
  VoteMsg(user_id, target_type, target_id, value)
}

// Direct message operations

pub fn send_direct_message(
  from_id: UserId,
  to_id: UserId,
  body: String,
) -> EngineMsg {
  SendDirectMessage(from_id, to_id, body)
}

pub fn get_direct_messages(user_id: UserId) -> EngineMsg {
  GetDirectMessages(user_id)
}

// Metrics operations

pub fn get_metrics() -> EngineMsg {
  GetMetrics
}

// Execute a message against the engine state
pub fn execute(state: State, msg: EngineMsg) -> #(State, EngineResponse) {
  engine.handle_message(state, msg)
}

// Batch execute multiple messages
pub fn execute_batch(
  state: State,
  messages: List(EngineMsg),
) -> #(State, List(EngineResponse)) {
  do_execute_batch(state, messages, [])
}

fn do_execute_batch(
  state: State,
  messages: List(EngineMsg),
  responses: List(EngineResponse),
) -> #(State, List(EngineResponse)) {
  case messages {
    [] -> #(state, list.reverse(responses))
    [msg, ..rest] -> {
      let #(new_state, response) = execute(state, msg)
      do_execute_batch(new_state, rest, [response, ..responses])
    }
  }
}
