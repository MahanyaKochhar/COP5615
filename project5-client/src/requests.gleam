import gleam/http
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import helpers
import io_models
import logging

const headers = [#("content-type", "application/json")]

pub fn create_user(email: String, password: String) {
  let user =
    json.to_string(
      json.object([
        #("email", json.string(email)),
        #("password", json.string(password)),
      ]),
    )
  let resp = helpers.send_request("api/user", http.Post, headers, user)
  case resp {
    Ok(resp) -> {
      let body = resp.body
      let parsed_response = json.parse(body, io_models.user_response_decoder())
      logging.log(logging.Info, "Register User Response Body")
      logging.log(logging.Info, body)
    }
    _ -> {
      logging.log(logging.Error, "HTTPC Error")
    }
  }
}

pub fn create_subreddit(name: String, email: String) {
  let subreddit =
    json.to_string(
      json.object([
        #("name", json.string(name)),
      ]),
    )
  let resp =
    helpers.send_request(
      "api/subreddit",
      http.Post,
      list.append(headers, [#("x-email", email)]),
      subreddit,
    )
  let subreddit_uuid = case resp {
    Ok(resp) -> {
      let body = resp.body
      let parsed_response =
        json.parse(body, io_models.entity_response_decoder())
      logging.log(logging.Info, "Subreddit Response Body")
      logging.log(logging.Info, body)
      case parsed_response {
        Ok(parsed_response) -> Some(parsed_response.uuid)
        _ -> None
      }
    }
    _ -> {
      logging.log(logging.Error, "HTTPC Error")
      None
    }
  }
}

pub type Member {
  Join
  Leave
}

pub fn handle_subreddit_membership(
  subreddit_id: String,
  email: String,
  status: Member,
) {
  let method = case status {
    Join -> http.Post
    Leave -> http.Delete
  }
  let req = json.to_string(json.object([]))
  let resp =
    helpers.send_request(
      "api/user/subreddit/" <> subreddit_id,
      method,
      list.append(headers, [#("x-email", email)]),
      req,
    )
  case resp {
    Ok(resp) -> {
      let body = resp.body
      logging.log(logging.Info, "Membership Response Body")
      logging.log(logging.Info, body)
    }
    _ -> {
      logging.log(logging.Error, "HTTPC Error")
    }
  }
}

pub fn create_post(subreddit_id: String, body: String, email: String) {
  let post = json.to_string(json.object([#("body", json.string(body))]))
  let resp =
    helpers.send_request(
      "api/subreddit/" <> subreddit_id <> "/post",
      http.Post,
      list.append(headers, [#("x-email", email)]),
      post,
    )
  let post_uuid = case resp {
    Ok(resp) -> {
      let body = resp.body
      let parsed_response =
        json.parse(body, io_models.entity_response_decoder())
      logging.log(logging.Info, "Post Response Body")
      logging.log(logging.Info, body)
      case parsed_response {
        Ok(parsed_response) -> Some(parsed_response.uuid)
        _ -> None
      }
    }
    _ -> {
      logging.log(logging.Error, "HTTPC Error")
      None
    }
  }
}

pub fn create_comment(
  post_id: String,
  comment_id: option.Option(String),
  body: String,
  email: String,
) {
  let path = case comment_id {
    Some(comment_id) -> "api/post/" <> post_id <> "/comment/" <> comment_id
    _ -> "api/post/" <> post_id <> "/comment"
  }
  let post = json.to_string(json.object([#("body", json.string(body))]))
  let resp =
    helpers.send_request(
      path,
      http.Post,
      list.append(headers, [#("x-email", email)]),
      post,
    )
  let comment_uuid = case resp {
    Ok(resp) -> {
      let body = resp.body
      let parsed_response =
        json.parse(body, io_models.entity_response_decoder())
      logging.log(logging.Info, "Comment Response Body")
      logging.log(logging.Info, body)
      case parsed_response {
        Ok(parsed_response) -> Some(parsed_response.uuid)
        _ -> None
      }
    }
    _ -> {
      logging.log(logging.Error, "HTTPC Error")
      None
    }
  }
}

pub fn vote(
  post_id: String,
  comment_id: option.Option(String),
  up: Int,
  down: Int,
  email: String,
) {
  let path = case comment_id {
    Some(comment_id) ->
      "api/post/" <> post_id <> "/comment/" <> comment_id <> "/vote"
    _ -> "api/post/" <> post_id <> "/vote"
  }
  let vote =
    json.to_string(
      json.object([#("up", json.int(up)), #("down", json.int(down))]),
    )
  let resp =
    helpers.send_request(
      path,
      http.Post,
      list.append(headers, [#("x-email", email)]),
      vote,
    )
  case resp {
    Ok(resp) -> {
      let body = resp.body
      logging.log(logging.Info, "Voting Response Body")
      logging.log(logging.Info, body)
    }
    _ -> {
      logging.log(logging.Error, "HTTPC Error")
    }
  }
}

pub fn feed(email: String) {
  let post = json.to_string(json.object([]))
  let resp =
    helpers.send_request(
      "api/user/feed",
      http.Get,
      list.append(headers, [#("x-email", email)]),
      post,
    )
  case resp {
    Ok(resp) -> {
      let body = resp.body
      logging.log(logging.Info, "Feed of User " <> email)
      logging.log(logging.Info, body)
    }
    _ -> {
      logging.log(logging.Error, "HTTPC Error")
    }
  }
}

pub fn user(email: String) {
  let user = json.to_string(json.object([]))
  let resp =
    helpers.send_request(
      "api/user",
      http.Get,
      list.append(headers, [#("x-email", email)]),
      user,
    )
  case resp {
    Ok(resp) -> {
      let body = resp.body
      logging.log(logging.Info, "User Profile " <> email)
      logging.log(logging.Info, body)
    }
    _ -> {
      logging.log(logging.Error, "HTTPC Error")
    }
  }
}

pub fn user_inbox(email: String) {
  let user = json.to_string(json.object([]))
  let resp =
    helpers.send_request(
      "api/user/inbox",
      http.Get,
      list.append(headers, [#("x-email", email)]),
      user,
    )
  case resp {
    Ok(resp) -> {
      let body = resp.body
      logging.log(logging.Info, "Inbox of User: " <> email)
      logging.log(logging.Info, body)
    }
    _ -> {
      logging.log(logging.Error, "HTTPC Error")
    }
  }
}
