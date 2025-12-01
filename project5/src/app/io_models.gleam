import gleam/dynamic/decode

pub type User {
  User(email: String, password: String)
}

pub type Subreddit {
  Subreddit(name: String)
}

pub type UserResponse {
  UserResponse(success: Bool, status: String, uuid: String)
}

pub type EntityResponse {
  EntityResponse(success: Bool, entity: String, uuid: String)
}

pub type Body {
  Body(body: String)
}

pub type Vote {
  Vote(up: Int, down: Int)
}

pub type Message {
  Message(recipient: String, body: String)
}

pub fn user_decoder() -> decode.Decoder(User) {
  use email <- decode.field("email", decode.string)
  use password <- decode.field("password", decode.string)
  decode.success(User(email:, password:))
}

pub fn subreddit_decoder() -> decode.Decoder(Subreddit) {
  use name <- decode.field("name", decode.string)
  decode.success(Subreddit(name:))
}

pub fn body_decoder() -> decode.Decoder(Body) {
  use body <- decode.field("body", decode.string)
  decode.success(Body(body:))
}

pub fn vote_decoder() -> decode.Decoder(Vote) {
  use up <- decode.field("up", decode.int)
  use down <- decode.field("down", decode.int)
  decode.success(Vote(up:, down:))
}

pub fn message_decoder() -> decode.Decoder(Message) {
  use recipient <- decode.field("recipient", decode.string)
  use body <- decode.field("body", decode.string)
  decode.success(Message(recipient:, body:))
}
