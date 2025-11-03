import engine.{
  type Action, type Request, CreateCommentClient, CreatePostClient,
  CreateSubRedditClient, GetAvailablePostsandCommentsClient,
  GetAvailableSubredditsClient, GetFeedClient, GetTTLInfoClient,
  JoinSubRedditClient, LeaveSubRedditClient, ReceiveMessageClient,
  RegisterClient, VoteClient,
}
import gleam/erlang/process
import gleam/otp/actor
import models

const call_milliseconds = 5000

pub fn handle_request(
  state: #(process.Subject(Action), String, Float),
  request: Request,
) -> actor.Next(#(process.Subject(Action), String, Float), Request) {
  let engine = state.0
  let authenticated_email = state.1
  case request {
    RegisterClient(email, password, client) -> {
      let result =
        actor.call(engine, call_milliseconds, engine.RegisterUser(
          email,
          password,
          _,
        ))
      actor.send(client, result)
      let updated_state = case result {
        Ok(result) -> #(state.0, result, state.2)
        Error(_result_) -> #(state.0, state.1, state.2)
      }
      actor.continue(updated_state)
    }
    CreateSubRedditClient(name, client) -> {
      let result =
        actor.call(engine, call_milliseconds, engine.CreateSubReddit(
          name,
          models.UserPrincipal(email: authenticated_email),
          _,
        ))
      actor.send(client, result)
      actor.continue(state)
    }
    JoinSubRedditClient(subreddit_uuid, client) -> {
      let result =
        actor.call(engine, call_milliseconds, engine.JoinSubReddit(
          subreddit_uuid,
          models.UserPrincipal(email: authenticated_email),
          _,
        ))
      actor.send(client, result)
      actor.continue(state)
    }
    LeaveSubRedditClient(subreddit_uuid, client) -> {
      let result =
        actor.call(engine, call_milliseconds, engine.LeaveSubReddit(
          subreddit_uuid,
          models.UserPrincipal(email: authenticated_email),
          _,
        ))
      actor.send(client, result)
      actor.continue(state)
    }
    CreatePostClient(subreddit_uuid, body, client) -> {
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
    CreateCommentClient(post_uuid, comment_uuid, body, client) -> {
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
    VoteClient(post_uuid, comment_uuid, up, down, client) -> {
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
    GetFeedClient(client) -> {
      let result =
        actor.call(engine, call_milliseconds, engine.GetFeed(
          models.UserPrincipal(email: authenticated_email),
          _,
        ))
      actor.send(client, result)
      actor.continue(state)
    }
    ReceiveMessageClient(sender_subject, recipient_subject, sender_email, body) -> {
      actor.send(
        engine,
        engine.SendMessage(
          sender_email,
          recipient_subject,
          sender_subject,
          "",
          models.UserPrincipal(email: authenticated_email),
        ),
      )
      actor.continue(state)
    }
    GetAvailableSubredditsClient(client) -> {
      let result =
        actor.call(engine, call_milliseconds, engine.GetAvailableSubreddits)
      actor.send(client, result)
      actor.continue(state)
    }
    GetAvailablePostsandCommentsClient(client) -> {
      let result =
        actor.call(
          engine,
          call_milliseconds,
          engine.GetAvailablePostsandComments,
        )
      actor.send(client, result)
      actor.continue(state)
    }
    GetTTLInfoClient(client) -> {
      actor.send(client, state.2)
      actor.continue(state)
    }
  }
}
