import gleam/dict.{type Dict}
import gleam/option.{type Option}

pub type UserPrincipal {
  UserPrincipal(email: String)
}

pub type User {
  User(
    id: Option(Int),
    uuid: Option(String),
    email: String,
    password: Option(String),
    stored_password: Option(BitArray),
  )
}

pub type SubReddit {
  SubReddit(
    id: Option(Int),
    uuid: Option(String),
    name: String,
    title: String,
    created_by: Option(Int),
    users: Option(List(Int)),
  )
}

pub type Post {
  Post(
    id: Option(Int),
    uuid: Option(String),
    subreddit_id: Option(Int),
    author_id: Option(Int),
    body: String,
  )
}

pub type Directory {
  Directory(
    users: Dict(String, User),
    subreddits: Dict(String, SubReddit),
    posts: Dict(String, Post),
    entities: Dict(Entity, Int),
  )
}

pub type Entity {
  UserEntity
  SubRedditEntity
  PostEntity
}
