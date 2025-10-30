import engine.{type Action}
import gleam/erlang/process
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import models

pub type Request {
  Register(String, String, process.Subject(Result(String, String)))
  CreateSubReddit(String, process.Subject(Result(String, String)))
  JoinSubReddit
  LeaveSubReddit
  CreatePost(String, String, process.Subject(Result(String, String)))
  CreateComment(
    String,
    Option(String),
    String,
    process.Subject(Result(String, String)),
  )
  Vote
  GetFeed
}

pub fn handle_request(
  state: #(process.Subject(Action), String),
  request: Request,
) -> actor.Next(#(process.Subject(Action), String), Request) {
  let engine = state.0
  let authenticated_email = state.1
  case request {
    Register(email, password, client) -> {
      let result =
        actor.call(engine, 1000, engine.RegisterUser(email, password, _))
      actor.send(client, result)
      actor.continue(state)
    }
    CreateSubReddit(name, client) -> {
      let result =
        actor.call(engine, 1000, engine.CreateSubReddit(
          name,
          models.UserPrincipal(email: authenticated_email),
          _,
        ))
      actor.send(client, result)
      actor.continue(state)
    }
    JoinSubReddit -> {
      todo
    }
    LeaveSubReddit -> {
      todo
    }
    CreatePost(subreddit_uuid, body, client) -> {
      let result =
        actor.call(engine, 1000, engine.CreatePost(
          subreddit_uuid,
          body,
          models.UserPrincipal(email: authenticated_email),
          _,
        ))
      actor.send(client, result)
      actor.continue(state)
    }
    CreateComment(post_uuid, comment_uuid, body, client) -> {
      let result =
        actor.call(engine, 1000, engine.CreateComment(
          post_uuid,
          comment_uuid,
          body,
          models.UserPrincipal(email: authenticated_email),
          _,
        ))
      actor.send(client, result)
      actor.continue(state)
    }
    Vote -> {
      todo
    }
    GetFeed -> {
      todo
    }
  }
}
