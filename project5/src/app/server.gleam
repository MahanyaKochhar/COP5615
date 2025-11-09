import app/router
import dot_env
import dot_env/env
import mist
import wisp
import wisp/wisp_mist

pub fn start() {
  wisp.configure_logger()

  dot_env.new()
  |> dot_env.set_path(".env")
  |> dot_env.set_debug(False)
  |> dot_env.load

  let assert Ok(secret_key_base) = env.get_string("SECRET_KEY_BASE")
  let ctx = Context(engine:)
  let assert Ok(_) =
    wisp_mist.handler(router.handle_request, secret_key_base)
    |> mist.new
    |> mist.bind("0.0.0.0")
    |> mist.port(8000)
    |> mist.start
}
