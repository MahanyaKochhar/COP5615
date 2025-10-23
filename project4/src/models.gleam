import gleam/dict.{type Dict}
import gleam/option.{type Option}

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
    member_count: Int,
  )
}

pub type Directory {
  Directory(
    users: Dict(String, User),
    subreddits: Dict(String, SubReddit),
    entities: Dict(Entity, Int),
  )
}

pub type Entity {
  UserEntity
  SubRedditEntity
  PostEntity
}
