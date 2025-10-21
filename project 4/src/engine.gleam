// engine.gleam - Core engine with state management and message handlers

import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import model.{
  type Comment, type CommentId, type DirectMessage, type EngineError,
  type EngineMsg, type EngineResponse, type FeedKind, type Metrics, type Post,
  type PostId, type Subreddit, type SubredditId, type TargetType, type User,
  type UserId, type Vote, type VoteKey, AlreadySubscribed, Comment,
  CommentCreated, CommentNotFound, CommentTarget, CreateComment, CreatePost,
  CreateSubreddit, DirectMessage, DirectMessageSent, DirectMessagesResult,
  Error, FeedResult, GetComments, GetDirectMessages, GetFeed, GetMetrics,
  GetPost, GetSubreddit, GetSubredditByName, GetUser, GetUserByName, Hot,
  InvalidInput, InvalidVoteValue, JoinSubreddit, JoinedSubreddit,
  LeaveSubreddit, LeftSubreddit, MetricsResult, New, NotSubscribed, Post,
  PostCreated, PostNotFound, PostResult, PostTarget, RegisterUser,
  SendDirectMessage, Subreddit, SubredditAlreadyExists, SubredditCreated,
  SubredditNotFound, SubredditResult, Top, User, UserAlreadyExists,
  UserCreated, UserNotFound, UserResult, Vote, VoteKey, VoteMsg,
  VoteRegistered,
}

// Engine state
pub type State {
  State(
    next_id: Int,
    users: Dict(UserId, User),
    users_by_name: Dict(String, UserId),
    subreddits: Dict(SubredditId, Subreddit),
    subreddits_by_name: Dict(String, SubredditId),
    posts: Dict(PostId, Post),
    comments: Dict(CommentId, Comment),
    votes: Dict(VoteKey, Vote),
    posts_by_subreddit: Dict(SubredditId, List(PostId)),
    posts_by_author: Dict(UserId, List(PostId)),
    comments_by_post: Dict(PostId, List(CommentId)),
    direct_messages: Dict(UserId, List(DirectMessage)),
    content_hashes: Dict(String, PostId),
  )
}

// Initialize new engine state
pub fn new() -> State {
  State(
    next_id: 1,
    users: dict.new(),
    users_by_name: dict.new(),
    subreddits: dict.new(),
    subreddits_by_name: dict.new(),
    posts: dict.new(),
    comments: dict.new(),
    votes: dict.new(),
    posts_by_subreddit: dict.new(),
    posts_by_author: dict.new(),
    comments_by_post: dict.new(),
    direct_messages: dict.new(),
    content_hashes: dict.new(),
  )
}

// Main message handler
pub fn handle_message(state: State, msg: EngineMsg) -> #(State, EngineResponse) {
  case msg {
    RegisterUser(username) -> handle_register_user(state, username)
    CreateSubreddit(name, owner_id) ->
      handle_create_subreddit(state, name, owner_id)
    JoinSubreddit(user_id, subreddit_id) ->
      handle_join_subreddit(state, user_id, subreddit_id)
    LeaveSubreddit(user_id, subreddit_id) ->
      handle_leave_subreddit(state, user_id, subreddit_id)
    CreatePost(author_id, subreddit_id, title, body) ->
      handle_create_post(state, author_id, subreddit_id, title, body)
    CreateComment(author_id, post_id, parent_id, body) ->
      handle_create_comment(state, author_id, post_id, parent_id, body)
    VoteMsg(voter_id, target_type, target_id, value) ->
      handle_vote(state, voter_id, target_type, target_id, value)
    GetFeed(user_id, subreddit_id, kind, limit) ->
      handle_get_feed(state, user_id, subreddit_id, kind, limit)
    GetPost(post_id) -> handle_get_post(state, post_id)
    GetComments(post_id) -> handle_get_comments(state, post_id)
    GetUser(user_id) -> handle_get_user(state, user_id)
    GetUserByName(username) -> handle_get_user_by_name(state, username)
    GetSubreddit(subreddit_id) -> handle_get_subreddit(state, subreddit_id)
    GetSubredditByName(name) -> handle_get_subreddit_by_name(state, name)
    SendDirectMessage(from_id, to_id, body) ->
      handle_send_dm(state, from_id, to_id, body)
    GetDirectMessages(user_id) -> handle_get_dms(state, user_id)
    GetMetrics -> handle_get_metrics(state)
  }
}

// Handler implementations

fn handle_register_user(state: State, username: String) -> #(State, EngineResponse) {
  case dict.has_key(state.users_by_name, username) {
    True -> #(state, Error(UserAlreadyExists))
    False -> {
      let user_id = state.next_id
      let user =
        User(
          id: user_id,
          username: username,
          created_at: get_timestamp(),
          karma: 0,
          subscribed: [],
        )
      
      let new_state =
        State(
          ..state,
          next_id: state.next_id + 1,
          users: dict.insert(state.users, user_id, user),
          users_by_name: dict.insert(state.users_by_name, username, user_id),
        )
      
      #(new_state, UserCreated(user))
    }
  }
}

fn handle_create_subreddit(
  state: State,
  name: String,
  owner_id: UserId,
) -> #(State, EngineResponse) {
  case dict.get(state.users, owner_id) {
    Error(_) -> #(state, Error(UserNotFound))
    Ok(_) ->
      case dict.has_key(state.subreddits_by_name, name) {
        True -> #(state, Error(SubredditAlreadyExists))
        False -> {
          let subreddit_id = state.next_id
          let subreddit =
            Subreddit(
              id: subreddit_id,
              name: name,
              member_count: 0,
              post_ids: [],
              created_at: get_timestamp(),
            )
          
          let new_state =
            State(
              ..state,
              next_id: state.next_id + 1,
              subreddits: dict.insert(state.subreddits, subreddit_id, subreddit),
              subreddits_by_name: dict.insert(
                state.subreddits_by_name,
                name,
                subreddit_id,
              ),
              posts_by_subreddit: dict.insert(
                state.posts_by_subreddit,
                subreddit_id,
                [],
              ),
            )
          
          #(new_state, SubredditCreated(subreddit))
        }
      }
  }
}

fn handle_join_subreddit(
  state: State,
  user_id: UserId,
  subreddit_id: SubredditId,
) -> #(State, EngineResponse) {
  case dict.get(state.users, user_id), dict.get(state.subreddits, subreddit_id) {
    Ok(user), Ok(subreddit) -> {
      case list.contains(user.subscribed, subreddit_id) {
        True -> #(state, Error(AlreadySubscribed))
        False -> {
          let updated_user =
            User(..user, subscribed: [subreddit_id, ..user.subscribed])
          let updated_subreddit =
            Subreddit(..subreddit, member_count: subreddit.member_count + 1)
          
          let new_state =
            State(
              ..state,
              users: dict.insert(state.users, user_id, updated_user),
              subreddits: dict.insert(
                state.subreddits,
                subreddit_id,
                updated_subreddit,
              ),
            )
          
          #(new_state, JoinedSubreddit)
        }
      }
    }
    Error(_), _ -> #(state, Error(UserNotFound))
    _, Error(_) -> #(state, Error(SubredditNotFound))
  }
}

fn handle_leave_subreddit(
  state: State,
  user_id: UserId,
  subreddit_id: SubredditId,
) -> #(State, EngineResponse) {
  case dict.get(state.users, user_id), dict.get(state.subreddits, subreddit_id) {
    Ok(user), Ok(subreddit) -> {
      case list.contains(user.subscribed, subreddit_id) {
        False -> #(state, Error(NotSubscribed))
        True -> {
          let updated_user =
            User(
              ..user,
              subscribed: list.filter(user.subscribed, fn(id) {
                id != subreddit_id
              }),
            )
          let updated_subreddit =
            Subreddit(..subreddit, member_count: subreddit.member_count - 1)
          
          let new_state =
            State(
              ..state,
              users: dict.insert(state.users, user_id, updated_user),
              subreddits: dict.insert(
                state.subreddits,
                subreddit_id,
                updated_subreddit,
              ),
            )
          
          #(new_state, LeftSubreddit)
        }
      }
    }
    Error(_), _ -> #(state, Error(UserNotFound))
    _, Error(_) -> #(state, Error(SubredditNotFound))
  }
}

fn handle_create_post(
  state: State,
  author_id: UserId,
  subreddit_id: SubredditId,
  title: String,
  body: String,
) -> #(State, EngineResponse) {
  case dict.get(state.users, author_id), dict.get(state.subreddits, subreddit_id) {
    Ok(_), Ok(subreddit) -> {
      case string.is_empty(title) {
        True -> #(state, Error(InvalidInput("Title cannot be empty")))
        False -> {
          let post_id = state.next_id
          let content_hash = hash_content(title, body)
          let repost_of = dict.get(state.content_hashes, content_hash) |> result.to_option
          
          let post =
            Post(
              id: post_id,
              author_id: author_id,
              subreddit_id: subreddit_id,
              title: title,
              body: body,
              created_at: get_timestamp(),
              score: 0,
              upvotes: 0,
              downvotes: 0,
              comment_count: 0,
              repost_of: repost_of,
            )
          
          let updated_subreddit =
            Subreddit(..subreddit, post_ids: [post_id, ..subreddit.post_ids])
          
          let subreddit_posts =
            dict.get(state.posts_by_subreddit, subreddit_id)
            |> result.unwrap([])
          
          let author_posts =
            dict.get(state.posts_by_author, author_id) |> result.unwrap([])
          
          let new_state =
            State(
              ..state,
              next_id: state.next_id + 1,
              posts: dict.insert(state.posts, post_id, post),
              subreddits: dict.insert(
                state.subreddits,
                subreddit_id,
                updated_subreddit,
              ),
              posts_by_subreddit: dict.insert(
                state.posts_by_subreddit,
                subreddit_id,
                [post_id, ..subreddit_posts],
              ),
              posts_by_author: dict.insert(
                state.posts_by_author,
                author_id,
                [post_id, ..author_posts],
              ),
              content_hashes: case repost_of {
                None -> dict.insert(state.content_hashes, content_hash, post_id)
                Some(_) -> state.content_hashes
              },
              comments_by_post: dict.insert(state.comments_by_post, post_id, []),
            )
          
          #(new_state, PostCreated(post))
        }
      }
    }
    Error(_), _ -> #(state, Error(UserNotFound))
    _, Error(_) -> #(state, Error(SubredditNotFound))
  }
}

fn handle_create_comment(
  state: State,
  author_id: UserId,
  post_id: PostId,
  parent_id: Option(CommentId),
  body: String,
) -> #(State, EngineResponse) {
  case dict.get(state.users, author_id), dict.get(state.posts, post_id) {
    Ok(_), Ok(post) -> {
      // Verify parent comment exists if specified
      let parent_valid = case parent_id {
        None -> True
        Some(pid) -> dict.has_key(state.comments, pid)
      }
      
      case parent_valid {
        False -> #(state, Error(CommentNotFound))
        True -> {
          let comment_id = state.next_id
          let comment =
            Comment(
              id: comment_id,
              post_id: post_id,
              author_id: author_id,
              parent_id: parent_id,
              body: body,
              created_at: get_timestamp(),
              children: [],
              score: 0,
              upvotes: 0,
              downvotes: 0,
            )
          
          let updated_post =
            Post(..post, comment_count: post.comment_count + 1)
          
          // Update parent comment's children list if applicable
          let updated_comments = case parent_id {
            None -> state.comments
            Some(pid) -> {
              case dict.get(state.comments, pid) {
                Ok(parent_comment) -> {
                  let updated_parent =
                    Comment(
                      ..parent_comment,
                      children: [comment_id, ..parent_comment.children],
                    )
                  dict.insert(state.comments, pid, updated_parent)
                }
                Error(_) -> state.comments
              }
            }
          }
          
          let post_comments =
            dict.get(state.comments_by_post, post_id) |> result.unwrap([])
          
          let new_state =
            State(
              ..state,
              next_id: state.next_id + 1,
              comments: dict.insert(updated_comments, comment_id, comment),
              posts: dict.insert(state.posts, post_id, updated_post),
              comments_by_post: dict.insert(
                state.comments_by_post,
                post_id,
                [comment_id, ..post_comments],
              ),
            )
          
          #(new_state, CommentCreated(comment))
        }
      }
    }
    Error(_), _ -> #(state, Error(UserNotFound))
    _, Error(_) -> #(state, Error(PostNotFound))
  }
}

fn handle_vote(
  state: State,
  voter_id: UserId,
  target_type: TargetType,
  target_id: Int,
  value: Int,
) -> #(State, EngineResponse) {
  case value != 1 && value != -1 {
    True -> #(state, Error(InvalidVoteValue))
    False -> {
      case dict.get(state.users, voter_id) {
        Error(_) -> #(state, Error(UserNotFound))
        Ok(_) -> {
          let vote_key = VoteKey(target_type, target_id, voter_id)
          let old_vote = dict.get(state.votes, vote_key) |> result.to_option
          
          let vote = Vote(voter_id, target_type, target_id, value)
          let new_votes = dict.insert(state.votes, vote_key, vote)
          
          // Calculate vote delta
          let delta = case old_vote {
            None -> value
            Some(Vote(_, _, _, old_value)) -> value - old_value
          }
          
          case target_type {
            PostTarget -> {
              case dict.get(state.posts, target_id) {
                Error(_) -> #(state, Error(PostNotFound))
                Ok(post) -> {
                  let #(new_upvotes, new_downvotes) = case delta {
                    2 -> #(post.upvotes + 1, post.downvotes - 1)
                    1 -> #(post.upvotes + 1, post.downvotes)
                    -1 -> #(post.upvotes, post.downvotes + 1)
                    -2 -> #(post.upvotes - 1, post.downvotes + 1)
                    _ -> #(post.upvotes, post.downvotes)
                  }
                  
                  let updated_post =
                    Post(
                      ..post,
                      upvotes: new_upvotes,
                      downvotes: new_downvotes,
                      score: new_upvotes - new_downvotes,
                    )
                  
                  // Update author karma
                  let author_result = dict.get(state.users, post.author_id)
                  let updated_users = case author_result {
                    Ok(author) -> {
                      let updated_author =
                        User(..author, karma: author.karma + delta)
                      dict.insert(state.users, post.author_id, updated_author)
                    }
                    Error(_) -> state.users
                  }
                  
                  let new_state =
                    State(
                      ..state,
                      posts: dict.insert(state.posts, target_id, updated_post),
                      votes: new_votes,
                      users: updated_users,
                    )
                  
                  #(new_state, VoteRegistered)
                }
              }
            }
            
            CommentTarget -> {
              case dict.get(state.comments, target_id) {
                Error(_) -> #(state, Error(CommentNotFound))
                Ok(comment) -> {
                  let #(new_upvotes, new_downvotes) = case delta {
                    2 -> #(comment.upvotes + 1, comment.downvotes - 1)
                    1 -> #(comment.upvotes + 1, comment.downvotes)
                    -1 -> #(comment.upvotes, comment.downvotes + 1)
                    -2 -> #(comment.upvotes - 1, comment.downvotes + 1)
                    _ -> #(comment.upvotes, comment.downvotes)
                  }
                  
                  let updated_comment =
                    Comment(
                      ..comment,
                      upvotes: new_upvotes,
                      downvotes: new_downvotes,
                      score: new_upvotes - new_downvotes,
                    )
                  
                  let author_result = dict.get(state.users, comment.author_id)
                  let updated_users = case author_result {
                    Ok(author) -> {
                      let updated_author =
                        User(..author, karma: author.karma + delta)
                      dict.insert(state.users, comment.author_id, updated_author)
                    }
                    Error(_) -> state.users
                  }
                  
                  let new_state =
                    State(
                      ..state,
                      comments: dict.insert(
                        state.comments,
                        target_id,
                        updated_comment,
                      ),
                      votes: new_votes,
                      users: updated_users,
                    )
                  
                  #(new_state, VoteRegistered)
                }
              }
            }
          }
        }
      }
    }
  }
}

fn handle_get_feed(
  state: State,
  _user_id: Option(UserId),
  subreddit_id: Option(SubredditId),
  kind: FeedKind,
  limit: Int,
) -> #(State, EngineResponse) {
  let posts = case subreddit_id {
    Some(sid) -> {
      dict.get(state.posts_by_subreddit, sid)
      |> result.unwrap([])
      |> list.filter_map(fn(pid) { dict.get(state.posts, pid) })
    }
    None -> dict.values(state.posts)
  }
  
  let sorted_posts = case kind {
    New -> list.sort(posts, fn(a, b) { compare_by_time(b, a) })
    Top -> list.sort(posts, fn(a, b) { compare_by_score(b, a) })
    Hot -> list.sort(posts, fn(a, b) { compare_by_hot(b, a) })
  }
  
  let limited_posts = list.take(sorted_posts, limit)
  
  #(state, FeedResult(limited_posts))
}

fn handle_get_post(state: State, post_id: PostId) -> #(State, EngineResponse) {
  case dict.get(state.posts, post_id) {
    Ok(post) -> #(state, PostResult(post))
    Error(_) -> #(state, Error(PostNotFound))
  }
}

fn handle_get_comments(
  state: State,
  post_id: PostId,
) -> #(State, EngineResponse) {
  case dict.get(state.posts, post_id) {
    Error(_) -> #(state, Error(PostNotFound))
    Ok(_) -> {
      let comment_ids =
        dict.get(state.comments_by_post, post_id) |> result.unwrap([])
      let comments =
        list.filter_map(comment_ids, fn(cid) { dict.get(state.comments, cid) })
      
      #(state, CommentsResult(comments))
    }
  }
}

fn handle_get_user(state: State, user_id: UserId) -> #(State, EngineResponse) {
  case dict.get(state.users, user_id) {
    Ok(user) -> #(state, UserResult(user))
    Error(_) -> #(state, Error(UserNotFound))
  }
}

fn handle_get_user_by_name(
  state: State,
  username: String,
) -> #(State, EngineResponse) {
  case dict.get(state.users_by_name, username) {
    Ok(user_id) -> handle_get_user(state, user_id)
    Error(_) -> #(state, Error(UserNotFound))
  }
}

fn handle_get_subreddit(
  state: State,
  subreddit_id: SubredditId,
) -> #(State, EngineResponse) {
  case dict.get(state.subreddits, subreddit_id) {
    Ok(subreddit) -> #(state, SubredditResult(subreddit))
    Error(_) -> #(state, Error(SubredditNotFound))
  }
}

fn handle_get_subreddit_by_name(
  state: State,
  name: String,
) -> #(State, EngineResponse) {
  case dict.get(state.subreddits_by_name, name) {
    Ok(subreddit_id) -> handle_get_subreddit(state, subreddit_id)
    Error(_) -> #(state, Error(SubredditNotFound))
  }
}

fn handle_send_dm(
  state: State,
  from_id: UserId,
  to_id: UserId,
  body: String,
) -> #(State, EngineResponse) {
  case dict.get(state.users, from_id), dict.get(state.users, to_id) {
    Ok(_), Ok(_) -> {
      let dm_id = state.next_id
      let dm =
        DirectMessage(
          id: dm_id,
          from_id: from_id,
          to_id: to_id,
          body: body,
          created_at: get_timestamp(),
          read: False,
        )
      
      let to_messages = dict.get(state.direct_messages, to_id) |> result.unwrap([])
      
      let new_state =
        State(
          ..state,
          next_id: state.next_id + 1,
          direct_messages: dict.insert(
            state.direct_messages,
            to_id,
            [dm, ..to_messages],
          ),
        )
      
      #(new_state, DirectMessageSent(dm))
    }
    Error(_), _ -> #(state, Error(UserNotFound))
    _, Error(_) -> #(state, Error(UserNotFound))
  }
}

fn handle_get_dms(
  state: State,
  user_id: UserId,
) -> #(State, EngineResponse) {
  case dict.get(state.users, user_id) {
    Error(_) -> #(state, Error(UserNotFound))
    Ok(_) -> {
      let messages = dict.get(state.direct_messages, user_id) |> result.unwrap([])
      #(state, DirectMessagesResult(messages))
    }
  }
}

fn handle_get_metrics(state: State) -> #(State, EngineResponse) {
  let metrics =
    model.Metrics(
      total_users: dict.size(state.users),
      total_subreddits: dict.size(state.subreddits),
      total_posts: dict.size(state.posts),
      total_comments: dict.size(state.comments),
      total_votes: dict.size(state.votes),
    )
  
  #(state, MetricsResult(metrics))
}

// Helper functions

fn get_timestamp() -> Int {
  // In real implementation, use proper BEAM timestamp
  // For now, return a placeholder
  0
}

fn hash_content(title: String, body: String) -> String {
  // Simple hash for repost detection
  // In real implementation, use proper hash function
  title <> "|" <> body
}

fn compare_by_time(a: Post, b: Post) -> gleam.order.Order {
  case a.created_at > b.created_at {
    True -> gleam.order.Gt
    False ->
      case a.created_at < b.created_at {
        True -> gleam.order.Lt
        False -> gleam.order.Eq
      }
  }
}

fn compare_by_score(a: Post, b: Post) -> gleam.order.Order {
  case a.score > b.score {
    True -> gleam.order.Gt
    False ->
      case a.score < b.score {
        True -> gleam.order.Lt
        False -> gleam.order.Eq
      }
  }
}

fn compare_by_hot(a: Post, b: Post) -> gleam.order.Order {
  let hot_a = calculate_hot_score(a)
  let hot_b = calculate_hot_score(b)
  
  case hot_a >. hot_b {
    True -> gleam.order.Gt
    False ->
      case hot_a <. hot_b {
        True -> gleam.order.Lt
        False -> gleam.order.Eq
      }
  }
}

fn calculate_hot_score(post: Post) -> Float {
  // Reddit-style hot ranking: score / (hours_since_creation + 2)^1.5
  let current_time = get_timestamp()
  let age_seconds = current_time - post.created_at
  let age_hours = int_to_float(age_seconds) /. 3600.0
  
  let score_float = int_to_float(post.score)
  let denominator = float_power(age_hours +. 2.0, 1.5)
  
  score_float /. denominator
}

fn int_to_float(i: Int) -> Float {
  // Helper to convert int to float
  case i {
    0 -> 0.0
    _ -> {
      let abs_i = case i < 0 {
        True -> -i
        False -> i
      }
      let result = do_int_to_float(abs_i, 0.0)
      case i < 0 {
        True -> 0.0 -. result
        False -> result
      }
    }
  }
}

fn do_int_to_float(i: Int, acc: Float) -> Float {
  case i {
    0 -> acc
    _ -> do_int_to_float(i / 10, acc *. 10.0 +. int_to_float_digit(i % 10))
  }
}

fn int_to_float_digit(d: Int) -> Float {
  case d {
    0 -> 0.0
    1 -> 1.0
    2 -> 2.0
    3 -> 3.0
    4 -> 4.0
    5 -> 5.0
    6 -> 6.0
    7 -> 7.0
    8 -> 8.0
    9 -> 9.0
    _ -> 0.0
  }
}

fn float_power(base: Float, exponent: Float) -> Float {
  // Simple power implementation for hot score calculation
  // For exponent = 1.5, we calculate base^1.5 = base * sqrt(base)
  case exponent {
    1.5 -> base *. float_sqrt(base)
    _ -> base
  }
}

fn float_sqrt(x: Float) -> Float {
  // Newton's method for square root
  case x <. 0.0 {
    True -> 0.0
    False -> sqrt_helper(x, x /. 2.0, 0)
  }
}

fn sqrt_helper(x: Float, guess: Float, iterations: Int) -> Float {
  case iterations > 10 {
    True -> guess
    False -> {
      let next_guess = { guess +. { x /. guess } } /. 2.0
      let diff = case guess >. next_guess {
        True -> guess -. next_guess
        False -> next_guess -. guess
      }
      case diff <. 0.0001 {
        True -> next_guess
        False -> sqrt_helper(x, next_guess, iterations + 1)
      }
    }
  }
}