import gleam/dict.{type Dict}
import gleam/erlang/process
import gleam/option.{type Option}
import mist

pub type MyMessage {
  Broadcast(String)
}

pub type UserPrincipal {
  UserPrincipal(email: String)
}

pub type User {
  User(
    id: Int,
    uuid: String,
    email: String,
    password: BitArray,
    karma: Int,
    websocket_subject: Option(process.Subject(MyMessage)),
  )
}

pub type SubReddit {
  SubReddit(
    id: Int,
    uuid: String,
    name: String,
    created_by: Int,
    users: List(Int),
  )
}

pub type Post {
  Post(
    id: Int,
    uuid: String,
    subreddit_id: Int,
    author_id: Int,
    body: String,
    upvote: Int,
    downvote: Int,
    comments: Option(List(CommentWithChildren)),
  )
}

pub type CommentWithChildren {
  CommentWithChildren(comment: Comment, children: List(CommentWithChildren))
}

pub type Comment {
  Comment(
    id: Int,
    uuid: String,
    author_id: Int,
    post_id: Int,
    parent_comment_id: Option(Int),
    body: String,
    upvote: Int,
    downvote: Int,
  )
}

pub type CommentTree {
  CommentTree(comment: Comment, children: List(CommentTree))
}

pub type Message {
  Message(
    id: Int,
    uuid: String,
    sender_id: Int,
    recipient_id: Int,
    body: String,
  )
}

pub type Metrics {
  Metrics(
    subreddit_metrics: List(SubRedditMetrics),
    post_with_max_vote_cnt: #(String, Int),
    user_with_max_posts: #(String, Int),
    user_with_max_comments: #(String, Int),
  )
}

pub type SubRedditMetrics {
  SubRedditMetrics(
    uuid: String,
    user_cnt: Int,
    posts_cnt: Int,
    comments_cnt: Int,
  )
}

pub type Directory {
  Directory(
    users: Dict(String, User),
    subreddits: Dict(String, SubReddit),
    posts: Dict(String, Post),
    comments: Dict(String, Comment),
    messages: Dict(String, Message),
    entities: Dict(Entity, Int),
  )
}

pub type Entity {
  UserEntity
  SubRedditEntity
  PostEntity
  CommentEntity
  MessageEntity
}
