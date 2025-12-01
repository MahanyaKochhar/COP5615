import app/server
import gleam/erlang/process
import logging

pub fn main() {
  logging.configure()
  logging.set_level(logging.Info)
  let assert Ok(_) = server.start()
  process.sleep_forever()
}
