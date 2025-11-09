import gleam/dynamic/decode

pub type User {
  User(email: String, password: String)
}

pub fn user_decoder() -> decode.Decoder(User) {
  use email <- decode.field("email", decode.string)
  use password <- decode.field("password", decode.string)
  decode.success(User(email:, password:))
}
