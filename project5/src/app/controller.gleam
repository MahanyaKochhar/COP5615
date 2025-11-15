import app/io_models
import engine
import gleam/dynamic/decode
import gleam/erlang/process
import gleam/json
import gleam/otp/actor
import models
import wisp.{type Request, type Response}

const call_milliseconds = 10_000

pub fn register_user(
  req: Request,
  engine: process.Subject(engine.Action),
) -> Response {
  use json_str <- wisp.require_json(req)
  let user = decode.run(json_str, io_models.user_decoder())
  case user {
    Ok(user) -> {
      let registered_user =
        actor.call(engine, call_milliseconds, engine.RegisterUser(
          user.email,
          user.password,
          _,
        ))
      case registered_user {
        Ok(register_user) -> {
          let user_response =
            io_models.UserResponse(
              success: True,
              status: "User Registered successfully.",
              uuid: register_user,
            )
          let response =
            json.object([
              #("success", json.bool(user_response.success)),
              #("status", json.string(user_response.status)),
            ])
            |> json.to_string()
          wisp.json_response(response, 201)
        }
        Error(register_user) -> {
          let user_response =
            io_models.UserResponse(
              success: False,
              status: register_user,
              uuid: "",
            )
          let response =
            json.object([
              #("success", json.bool(user_response.success)),
              #("status", json.string(user_response.status)),
            ])
            |> json.to_string()
          wisp.json_response(response, 400)
        }
      }
    }
    _ -> {
      wisp.bad_request("Invalid JSON.")
    }
  }
}

pub fn create_subreddit(
  req: Request,
  engine: process.Subject(engine.Action),
  user_email: String,
) -> Response {
  use json_str <- wisp.require_json(req)
  let subreddit = decode.run(json_str, io_models.subreddit_decoder())
  case subreddit {
    Ok(subreddit) -> {
      let created_subreddit =
        actor.call(engine, call_milliseconds, engine.CreateSubReddit(
          subreddit.name,
          models.UserPrincipal(email: user_email),
          _,
        ))
      case created_subreddit {
        Ok(created_subreddit) -> {
          let subreddit_response =
            io_models.SubredditResponse(success: True, uuid: created_subreddit)
          let response =
            json.object([
              #("success", json.bool(subreddit_response.success)),
              #("uuid", json.string(subreddit_response.uuid)),
              #("name", json.string(subreddit.name)),
            ])
            |> json.to_string()
          wisp.json_response(response, 201)
        }
        _ -> {
          wisp.response(403)
        }
      }
    }
    _ -> {
      wisp.bad_request("Invalid JSON.")
    }
  }
}

pub fn join_subreddit(
  req: Request,
  engine: process.Subject(engine.Action),
  subreddit_uuid: String,
  user_email: String,
) -> Response {
  let join_request =
    actor.call(engine, call_milliseconds, engine.JoinSubReddit(
      subreddit_uuid,
      models.UserPrincipal(email: user_email),
      _,
    ))
  case join_request {
    Ok(join_request) -> {
      let response =
        json.object([
          #("success", json.bool(True)),
        ])
        |> json.to_string()
      wisp.json_response(response, 200)
    }
    Error(join_request) -> {
      case join_request {
        "Subreddit does not exist." -> {
          let response =
            json.object([
              #("success", json.bool(False)),
              #("status", json.string(join_request)),
            ])
            |> json.to_string()
          wisp.json_response(response, 400)
        }
        _ -> wisp.response(403)
      }
    }
  }
}

pub fn leave_subreddit(
  req: Request,
  engine: process.Subject(engine.Action),
  subreddit_uuid: String,
  user_email: String,
) -> Response {
  let leave_request =
    actor.call(engine, call_milliseconds, engine.LeaveSubReddit(
      subreddit_uuid,
      models.UserPrincipal(email: user_email),
      _,
    ))
  case leave_request {
    Ok(leave_request) -> {
      let response =
        json.object([
          #("success", json.bool(True)),
        ])
        |> json.to_string()
      wisp.json_response(response, 200)
    }
    Error(leave_request) -> {
      case leave_request {
        "Subreddit does not exist." -> {
          let response =
            json.object([
              #("success", json.bool(False)),
              #("status", json.string(leave_request)),
            ])
            |> json.to_string()
          wisp.json_response(response, 400)
        }
        _ -> wisp.response(403)
      }
    }
  }
}
