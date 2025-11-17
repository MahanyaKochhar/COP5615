import app/controller
import app/web.{type Context}
import engine
import gleam/erlang/process
import gleam/http.{Delete, Get, Post}
import gleam/http/request
import gleam/option.{None, Some}
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
    ["api", "subreddit", subreddit_id, "post"] ->
      create_post(req, ctx.engine, subreddit_id, user_email)
    ["api", "post", post_id, "comment"] ->
      create_comment(req, ctx.engine, post_id, option.None, user_email)
    ["api", "post", post_id, "comment", comment_id] ->
      create_comment(
        req,
        ctx.engine,
        post_id,
        option.Some(comment_id),
        user_email,
      )
    ["api", "post", post_id, "comment", "vote"] -> {
      vote(req, ctx.engine, post_id, None, user_email)
    }
    ["api", "post", post_id, "comment", comment_id, "vote"] -> {
      vote(req, ctx.engine, post_id, Some(comment_id), user_email)
    }
    ["api", "user", "feed"] -> {
      feed(req, ctx.engine, user_email)
    }
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

fn create_post(
  req: Request,
  engine: process.Subject(engine.Action),
  subreddit_id: String,
  user_email: Result(String, Nil),
) {
  use <- wisp.require_method(req, Post)
  case user_email {
    Ok(user_email) -> {
      controller.create_post(req, engine, subreddit_id, user_email)
    }
    _ -> {
      wisp.response(401)
    }
  }
}

fn create_comment(
  req: Request,
  engine: process.Subject(engine.Action),
  post_id: String,
  comment_id: option.Option(String),
  user_email: Result(String, Nil),
) {
  use <- wisp.require_method(req, Post)
  case user_email {
    Ok(user_email) -> {
      controller.create_comment(req, engine, post_id, comment_id, user_email)
    }
    _ -> {
      wisp.response(401)
    }
  }
}

fn vote(
  req: Request,
  engine: process.Subject(engine.Action),
  post_id: String,
  comment_id: option.Option(String),
  user_email: Result(String, Nil),
) {
  use <- wisp.require_method(req, Post)
  case user_email {
    Ok(user_email) -> {
      controller.vote(req, engine, post_id, comment_id, user_email)
    }
    _ -> {
      wisp.response(401)
    }
  }
}

fn feed(
  req: Request,
  engine: process.Subject(engine.Action),
  user_email: Result(String, Nil),
) {
  case user_email {
    Ok(user_email) -> {
      controller.feed(req, engine, user_email)
    }
    _ -> {
      wisp.response(401)
    }
  }
}
