import gleam/dynamic/decode
import gleam/option

pub type User {
  User(email: String, password: String, pubkey: option.Option(String))
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
  Body(body: String, signature: option.Option(String))
}

pub type Vote {
  Vote(up: Int, down: Int)
}

pub type Message {
  Message(recipient: String, body: String)
}

pub type Pubkey {
  Pubkey(pubkey: option.Option(String))
}

pub fn user_decoder() -> decode.Decoder(User) {
  use email <- decode.field("email", decode.string)
  use password <- decode.field("password", decode.string)
  use pubkey <- decode.field("pubkey", decode.optional(decode.string))
  decode.success(User(email:, password:, pubkey:))
}

pub fn subreddit_decoder() -> decode.Decoder(Subreddit) {
  use name <- decode.field("name", decode.string)
  decode.success(Subreddit(name:))
}

pub fn body_decoder() -> decode.Decoder(Body) {
  use body <- decode.field("body", decode.string)
  use signature <- decode.field("signature", decode.optional(decode.string))
  decode.success(Body(body:, signature:))
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

pub fn pubkey_decoder() -> decode.Decoder(Pubkey) {
  use pubkey <- decode.field("pubkey", decode.optional(decode.string))
  decode.success(Pubkey(pubkey:))
}
