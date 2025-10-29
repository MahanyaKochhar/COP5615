import gleam/dict.{type Dict}
import gleam/option.{type Option}

pub type UserPrincipal {
  UserPrincipal(email: String)
}

pub type User {
  User(id: Int, uuid: String, email: String, password: BitArray, karma: Int)
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

pub type Directory {
  Directory(
    users: Dict(String, User),
    subreddits: Dict(String, SubReddit),
    posts: Dict(String, Post),
    comments: Dict(String, Comment),
    entities: Dict(Entity, Int),
  )
}

pub type Entity {
  UserEntity
  SubRedditEntity
  PostEntity
  CommentEntity
}
