import app/server
import gleam/erlang/process
import gleam/io
import radiate

pub fn main() {
  let _ =
    radiate.new()
    |> radiate.add_dir(
      "/Users/mahanyakochhar/Desktop/COP5615/projects/project5/src",
    )
    |> radiate.on_reload(fn(_state, path) {
      io.println("Change in " <> path <> ", reloading now!")
    })
    |> radiate.start()
  let assert Ok(_) = server.start()
  process.sleep_forever()
}
