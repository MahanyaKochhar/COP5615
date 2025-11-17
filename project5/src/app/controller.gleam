import app/io_models
import engine
import gleam/dynamic/decode
import gleam/erlang/process
import gleam/json
import gleam/option
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
              #("uuid", json.string(user_response.uuid)),
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
            io_models.EntityResponse(
              success: True,
              uuid: created_subreddit,
              entity: "SUBREDDIT",
            )
          let response =
            json.object([
              #("success", json.bool(subreddit_response.success)),
              #("uuid", json.string(subreddit_response.uuid)),
              #("entity", json.string(subreddit_response.entity)),
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

pub fn create_post(
  req: Request,
  engine: process.Subject(engine.Action),
  subreddit_uuid: String,
  user_email: String,
) -> Response {
  use json_str <- wisp.require_json(req)
  let post = decode.run(json_str, io_models.body_decoder())
  case post {
    Ok(post) -> {
      let created_post =
        actor.call(engine, call_milliseconds, engine.CreatePost(
          subreddit_uuid,
          post.body,
          models.UserPrincipal(email: user_email),
          _,
        ))
      case created_post {
        Ok(created_post) -> {
          let post_response =
            io_models.EntityResponse(
              success: True,
              entity: "POST",
              uuid: created_post,
            )
          let response =
            json.object([
              #("success", json.bool(post_response.success)),
              #("entity", json.string(post_response.entity)),
              #("uuid", json.string(post_response.uuid)),
            ])
            |> json.to_string()
          wisp.json_response(response, 201)
        }
        Error(created_post) -> {
          case created_post {
            "Subreddit does not exist." -> {
              let response =
                json.object([
                  #("success", json.bool(False)),
                  #("status", json.string(created_post)),
                ])
                |> json.to_string()
              wisp.json_response(response, 400)
            }
            _ -> wisp.response(403)
          }
        }
      }
    }
    _ -> {
      wisp.bad_request("Invalid JSON.")
    }
  }
}

pub fn create_comment(
  req: Request,
  engine: process.Subject(engine.Action),
  post_uuid: String,
  comment_uuid: option.Option(String),
  user_email: String,
) {
  use json_str <- wisp.require_json(req)
  let comment = decode.run(json_str, io_models.body_decoder())
  case comment {
    Ok(comment) -> {
      let created_comment =
        actor.call(engine, call_milliseconds, engine.CreateComment(
          post_uuid,
          comment_uuid,
          comment.body,
          models.UserPrincipal(email: user_email),
          _,
        ))
      case created_comment {
        Ok(created_comment) -> {
          let comment_response =
            io_models.EntityResponse(
              success: True,
              entity: "COMMENT",
              uuid: created_comment,
            )
          let response =
            json.object([
              #("success", json.bool(comment_response.success)),
              #("entity", json.string(comment_response.entity)),
              #("uuid", json.string(comment_response.uuid)),
            ])
            |> json.to_string()
          wisp.json_response(response, 201)
        }
        Error(created_comment) -> {
          case created_comment {
            "Invalid Post." -> {
              let response =
                json.object([
                  #("success", json.bool(False)),
                  #("status", json.string(created_comment)),
                ])
                |> json.to_string()
              wisp.json_response(response, 400)
            }
            _ -> wisp.response(403)
          }
        }
      }
    }
    _ -> wisp.bad_request("Invalid JSON.")
  }
}

pub fn vote(
  req: Request,
  engine: process.Subject(engine.Action),
  post_uuid: String,
  comment_uuid: option.Option(String),
  user_email: String,
) {
  use json_str <- wisp.require_json(req)
  let vote = decode.run(json_str, io_models.vote_decoder())
  case vote {
    Ok(vote) -> {
      let created_vote =
        actor.call(engine, call_milliseconds, engine.Vote(
          post_uuid,
          comment_uuid,
          vote.up,
          vote.down,
          models.UserPrincipal(email: user_email),
          _,
        ))

      case created_vote {
        Ok(created_vote) -> {
          let response =
            json.object([
              #("success", json.bool(True)),
              #("status", json.string(created_vote)),
            ])
            |> json.to_string()
          wisp.json_response(response, 200)
        }
        Error(created_vote) -> {
          case created_vote {
            "Invalid Post." -> {
              let response =
                json.object([
                  #("success", json.bool(False)),
                  #("status", json.string(created_vote)),
                ])
                |> json.to_string()
              wisp.json_response(response, 400)
            }
            _ -> {
              wisp.response(403)
            }
          }
        }
      }
    }
    _ -> wisp.bad_request("Invalid JSON.")
  }
}

fn comment1_to_json() {
  todo
}

fn comment_to_json(comment: models.CommentWithChildren) {
  json.object([#("comment")])
}

fn post_to_json(post: models.Post) {
  let comments = case post.comments {
    option.Some(comments) -> {
      comments
    }
    _ -> []
  }
  json.object([
    #("uuid", json.string(post.uuid)),
    #("body", json.string(post.body)),
    #("upvote", json.int(post.upvote)),
    #("downvote", json.int(post.downvote)),
    #("comments", json.array(comments, comment_to_json)),
  ])
}

pub fn feed(
  req: Request,
  engine: process.Subject(engine.Action),
  user_email: String,
) -> Response {
  let user_feed =
    actor.call(engine, call_milliseconds, engine.GetFeed(
      models.UserPrincipal(email: user_email),
      _,
    ))
  case user_feed {
    Ok(user_feed) -> {
      let json_str = json.array(user_feed, post_to_json) |> json.to_string()
      wisp.json_response(json_str, 200)
    }
    _ -> {
      wisp.response(403)
    }
  }
}
