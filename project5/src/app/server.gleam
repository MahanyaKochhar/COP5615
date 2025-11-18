import app/router
import app/web.{Context}
import dot_env
import dot_env/env
import engine
import gleam/dict
import gleam/http/request.{type Request}
import gleam/otp/actor
import mist.{type Connection, type ResponseData}
import models
import wisp
import wisp/wisp_mist

pub fn start() {
  wisp.configure_logger()

  dot_env.new()
  |> dot_env.set_path(".env")
  |> dot_env.set_debug(False)
  |> dot_env.load

  let assert Ok(secret_key_base) = env.get_string("SECRET_KEY_BASE")

  let base_directory =
    models.Directory(
      dict.new(),
      dict.new(),
      dict.new(),
      dict.new(),
      dict.new(),
      dict.new(),
    )
  let assert Ok(engine_actor) =
    actor.new(base_directory)
    |> actor.on_message(engine.handle_action)
    |> actor.start

  let subject = engine_actor.data
  let ctx = Context(engine: subject)
  let handler = router.handle_request(_, ctx)
  let assert Ok(_) =
    fn(req: Request(Connection)) {
      case request.path_segments(req) {
        ["ws"] -> {
          todo
        }
        _ -> wisp_mist.handler(handler, secret_key_base)(req)
      }
    }
    |> mist.new
    |> mist.bind("0.0.0.0")
    |> mist.port(8000)
    |> mist.start
}
