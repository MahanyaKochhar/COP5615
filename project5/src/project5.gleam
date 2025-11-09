import app/server
import gleam/erlang/process

pub fn main() {
  let assert Ok(_) = server.start()
  process.sleep_forever()
}
