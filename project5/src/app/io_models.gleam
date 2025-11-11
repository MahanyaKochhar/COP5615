import gleam/dynamic/decode

pub type User {
  User(email: String, password: String)
}

pub type Subreddit {
  Subreddit(name: String)
}

pub type UserResponse {
  UserResponse(success: Bool, status: String)
}

pub type SubredditResponse {
  SubredditResponse(success: Bool, uuid: String)
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
