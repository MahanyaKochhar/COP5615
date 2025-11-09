import app/io_models
import gleam/dynamic/decode
import gleam/result
import wisp.{type Request, type Response}

pub fn register_user(req: Request) -> Response {
  use json <- wisp.require_json(req)
  let user = decode.run(json, io_models.user_decoder())
  case user {
    Ok(user) -> {
      wisp.ok() |> wisp.html_body("Ok")
    }
    _ -> {
      wisp.internal_server_error()
    }
  }
}
