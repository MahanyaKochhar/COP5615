import app/controller
import app/web.{type Context}
import engine
import gleam/erlang/process
import gleam/http.{Delete, Get, Post}
import gleam/http/request
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- web.middleware(req)
  let user_email = request.get_header(req, "x-email")
  case wisp.path_segments(req) {
    ["api", "user"] -> register_user(req, ctx.engine)
    ["api", "subreddit"] -> subreddit(req, ctx.engine, user_email)
    ["api", "user", user_id, "subreddit", subreddit_id] ->
      handle_user_subreddit_membership(
        req,
        ctx.engine,
        subreddit_id,
        user_email,
      )
    // ["comments"] -> comments(req)
    // ["comments", id] -> show_comment(req, id)
    _ -> wisp.not_found()
  }
}

fn register_user(req: Request, engine: process.Subject(engine.Action)) {
  use <- wisp.require_method(req, Post)
  controller.register_user(req, engine)
}

fn subreddit(
  req: Request,
  engine: process.Subject(engine.Action),
  user_email: Result(String, Nil),
) {
  use <- wisp.require_method(req, Post)
  case user_email {
    Ok(user_email) -> {
      controller.create_subreddit(req, engine, user_email)
    }
    _ -> {
      wisp.response(401)
    }
  }
}

fn handle_user_subreddit_membership(
  req: Request,
  engine: process.Subject(engine.Action),
  subreddit_id: String,
  user_email: Result(String, Nil),
) {
  case user_email {
    Ok(user_email) -> {
      case req.method {
        Post -> controller.join_subreddit(req, engine, subreddit_id, user_email)
        Delete ->
          controller.leave_subreddit(req, engine, subreddit_id, user_email)
        _ -> wisp.method_not_allowed([Post, Delete])
      }
    }
    _ -> {
      wisp.response(401)
    }
  }
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
