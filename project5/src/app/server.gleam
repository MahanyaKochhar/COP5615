import app/router
import app/web.{Context}
import dot_env
import dot_env/env
import engine
import gleam/bytes_tree
import gleam/dict
import gleam/erlang/process
import gleam/http/request.{type Request}
import gleam/http/response
import gleam/io
import gleam/option.{None, Some}
import gleam/otp/actor
import gleam/string
import logging
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
      logging.log(
        logging.Info,
        "Got a request from: " <> string.inspect(mist.get_client_info(req.body)),
      )
      case request.path_segments(req) {
        ["ws"] -> {
          case request.get_header(req, "x-email") {
            Ok(email) -> {
              mist.websocket(
                request: req,
                on_init: fn(conn) {
                  let websocket_subject = process.new_subject()
                  router.save_subject(email, websocket_subject, subject)
                  let selector =
                    process.new_selector()
                    |> process.select(websocket_subject)
                  logging.log(logging.Info, "Websocket Connection Complete.")
                  #(#(subject, email), Some(selector))
                },
                on_close: fn(_state) {
                  logging.log(logging.Info, "Websocket Connection Closed.")
                },
                handler: router.handle_ws_request,
              )
            }
            _ -> {
              response.new(401)
              |> response.set_body(mist.Bytes(bytes_tree.new()))
            }
          }
        }
        _ -> wisp_mist.handler(handler, secret_key_base)(req)
      }
    }
    |> mist.new
    |> mist.bind("0.0.0.0")
    |> mist.port(8000)
    |> mist.start
}
