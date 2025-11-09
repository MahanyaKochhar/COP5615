import app/controller
import app/web
import gleam/http.{Get, Post}
import wisp.{type Request, type Response}

pub fn handle_request(req: Request) -> Response {
  use req <- web.middleware(req)
  case wisp.path_segments(req) {
    ["api", "user"] -> register_user(req)
    ["api", "subreddit"] -> home_page(req)
    // ["comments"] -> comments(req)
    // ["comments", id] -> show_comment(req, id)
    _ -> wisp.not_found()
  }
}

fn register_user(req: Request) {
  use <- wisp.require_method(req, Post)
  controller.register_user(req)
}

fn home_page(req: Request) -> Response {
  use <- wisp.require_method(req, Post)

  wisp.ok()
  |> wisp.html_body("Hello, Mahanya")
}
// fn comments(req: Request) -> Response {
//   case req.method {
//     Get -> list_comments()
//     Post -> create_comment(req)
//     _ -> wisp.method_not_allowed([Get, Post])
//   }
// }

// fn list_comments() -> Response {
//   wisp.ok()
//   |> wisp.html_body("Comments!")
// }

// fn create_comment(_req: Request) -> Response {
//   wisp.created()
//   |> wisp.html_body("Created")
// }

// fn show_comment(req: Request, id: String) -> Response {
//   use <- wisp.require_method(req, Get)

//   wisp.ok()
//   |> wisp.html_body("Comment with id " <> id)
// }
