import engine.{type Action}
import gleam/erlang/process
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import models

const call_milliseconds = 5000

pub type Request {
  Register(String, String, process.Subject(Result(String, String)))
  CreateSubReddit(String, process.Subject(Result(String, String)))
  JoinSubReddit(String, process.Subject(Result(String, String)))
  LeaveSubReddit(String, process.Subject(Result(String, String)))
  CreatePost(String, String, process.Subject(Result(String, String)))
  CreateComment(
    String,
    Option(String),
    String,
    process.Subject(Result(String, String)),
  )
  Vote(
    String,
    Option(String),
    Int,
    Int,
    process.Subject(Result(String, String)),
  )
  GetFeed(process.Subject(Result(List(models.Post), String)))
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
        actor.call(engine, call_milliseconds, engine.RegisterUser(
          email,
          password,
          _,
        ))
      actor.send(client, result)
      let updated_state = case result {
        Ok(result) -> #(state.0, result)
        Error(result) -> #(state.0, state.1)
      }
      actor.continue(updated_state)
    }
    CreateSubReddit(name, client) -> {
      let result =
        actor.call(engine, call_milliseconds, engine.CreateSubReddit(
          name,
          models.UserPrincipal(email: authenticated_email),
          _,
        ))
      actor.send(client, result)
      actor.continue(state)
    }
    JoinSubReddit(subreddit_uuid, client) -> {
      let result =
        actor.call(engine, call_milliseconds, engine.JoinSubReddit(
          subreddit_uuid,
          models.UserPrincipal(email: authenticated_email),
          _,
        ))
      actor.send(client, result)
      actor.continue(state)
    }
    LeaveSubReddit(subreddit_uuid, client) -> {
      let result =
        actor.call(engine, call_milliseconds, engine.LeaveSubReddit(
          subreddit_uuid,
          models.UserPrincipal(email: authenticated_email),
          _,
        ))
      actor.send(client, result)
      actor.continue(state)
    }
    CreatePost(subreddit_uuid, body, client) -> {
      let result =
        actor.call(engine, call_milliseconds, engine.CreatePost(
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
        actor.call(engine, call_milliseconds, engine.CreateComment(
          post_uuid,
          comment_uuid,
          body,
          models.UserPrincipal(email: authenticated_email),
          _,
        ))
      actor.send(client, result)
      actor.continue(state)
    }
    Vote(post_uuid, comment_uuid, up, down, client) -> {
      let result =
        actor.call(engine, call_milliseconds, engine.Vote(
          post_uuid,
          comment_uuid,
          up,
          down,
          models.UserPrincipal(email: authenticated_email),
          _,
        ))
      actor.send(client, result)
      actor.continue(state)
    }
    GetFeed(client) -> {
      let result =
        actor.call(engine, call_milliseconds, engine.GetFeed(
          models.UserPrincipal(email: authenticated_email),
          _,
        ))
      actor.send(client, result)
      actor.continue(state)
    }
  }
}
