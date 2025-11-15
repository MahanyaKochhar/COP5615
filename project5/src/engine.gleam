import gleam/bit_array
import gleam/crypto
import gleam/dict.{type Dict}
import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/result
import helpers
import models.{
  type Directory, type Post, type UserPrincipal, Comment, CommentEntity,
  Directory, Message, MessageEntity, Metrics, Post, PostEntity, SubReddit,
  SubRedditEntity, SubRedditMetrics, User, UserEntity,
}
import youid/uuid

pub type Request {
  RegisterClient(String, String, process.Subject(Result(String, String)))
  CreateSubRedditClient(String, process.Subject(Result(String, String)))
  JoinSubRedditClient(String, process.Subject(Result(String, String)))
  LeaveSubRedditClient(String, process.Subject(Result(String, String)))
  CreatePostClient(String, String, process.Subject(Result(String, String)))
  CreateCommentClient(
    String,
    Option(String),
    String,
    process.Subject(Result(String, String)),
  )
  VoteClient(
    String,
    Option(String),
    Int,
    Int,
    process.Subject(Result(String, String)),
  )
  GetFeedClient(process.Subject(Result(List(models.Post), String)))
  ReceiveMessageClient(
    process.Subject(Request),
    process.Subject(Request),
    String,
    String,
  )
  GetAvailableSubredditsClient(process.Subject(List(String)))
  GetAvailablePostsandCommentsClient(
    process.Subject(List(#(String, List(String)))),
  )
  GetTTLInfoClient(process.Subject(Float))
}

pub type Action {
  RegisterUser(String, String, process.Subject(Result(String, String)))
  CreateSubReddit(
    String,
    UserPrincipal,
    process.Subject(Result(String, String)),
  )
  JoinSubReddit(String, UserPrincipal, process.Subject(Result(String, String)))
  LeaveSubReddit(String, UserPrincipal, process.Subject(Result(String, String)))
  CreatePost(
    String,
    String,
    UserPrincipal,
    process.Subject(Result(String, String)),
  )
  CreateComment(
    String,
    Option(String),
    String,
    UserPrincipal,
    process.Subject(Result(String, String)),
  )
  Vote(
    String,
    Option(String),
    Int,
    Int,
    UserPrincipal,
    process.Subject(Result(String, String)),
  )
  GetFeed(UserPrincipal, process.Subject(Result(List(Post), String)))
  SendMessage(
    String,
    process.Subject(Request),
    process.Subject(Request),
    String,
    UserPrincipal,
  )
  GetAvailableSubreddits(process.Subject(List(String)))
  GetAvailablePostsandComments(process.Subject(List(#(String, List(String)))))
  GetMetrics(process.Subject(models.Metrics))
  GetState
}

pub fn handle_action(
  state: Directory,
  action: Action,
) -> actor.Next(Directory, Action) {
  case action {
    RegisterUser(email, password, client) -> {
      let entity_dict = state.entities
      let user_dict = state.users
      let is_already_registered = dict.has_key(user_dict, email)
      let updated_directory = case is_already_registered {
        True -> {
          io.println("Email " <> email <> " is already registered.")
          actor.send(client, Error("Email is already registered."))
          state
        }
        False -> {
          let user_entity_cnt =
            dict.get(entity_dict, UserEntity) |> result.unwrap(1)
          let created_user =
            User(
              id: user_entity_cnt,
              uuid: uuid.v4_string(),
              email: email,
              password: crypto.hash(
                crypto.Sha256,
                bit_array.from_string(password),
              ),
              karma: 0,
            )
          let updated_user_dict = dict.insert(user_dict, email, created_user)
          let updated_entity_dict =
            dict.insert(entity_dict, UserEntity, user_entity_cnt + 1)
          actor.send(client, Ok(email))
          Directory(
            ..state,
            users: updated_user_dict,
            entities: updated_entity_dict,
          )
        }
      }
      actor.continue(updated_directory)
    }
    CreateSubReddit(name, user_principal, client) -> {
      let user_email = user_principal.email
      case dict.get(state.users, user_email) {
        Ok(user) -> {
          let user_id = user.id
          let entity_dict = state.entities
          let subreddit_dict = state.subreddits
          let subreddit_entity_cnt =
            dict.get(entity_dict, SubRedditEntity) |> result.unwrap(1)
          let uuid = uuid.v4_string()
          let created_subreddit =
            SubReddit(
              id: subreddit_entity_cnt,
              uuid: uuid,
              name: name,
              created_by: user_id,
              users: [user_id],
            )
          let updated_subreddit_dict =
            dict.insert(subreddit_dict, uuid, created_subreddit)
          let updated_entity_dict =
            dict.insert(entity_dict, SubRedditEntity, subreddit_entity_cnt + 1)
          let updated_directory =
            Directory(
              ..state,
              subreddits: updated_subreddit_dict,
              entities: updated_entity_dict,
            )
          actor.send(client, Ok(uuid))
          actor.continue(updated_directory)
        }
        _ -> {
          io.println("Invalid user.")
          actor.send(client, Error("Invalid User."))
          actor.continue(state)
        }
      }
    }
    JoinSubReddit(subreddit_uuid, user_principal, client) -> {
      let user_email = user_principal.email
      case dict.get(state.users, user_email) {
        Ok(user) -> {
          let user_id = user.id
          let subreddit_dict = state.subreddits
          let updated_subreddit_dict = case
            dict.get(subreddit_dict, subreddit_uuid)
          {
            Ok(subreddit) -> {
              let users = subreddit.users
              let subreddit_dict = case list.contains(users, user_id) {
                True -> {
                  subreddit_dict
                }
                False -> {
                  let upd_user_list = list.append(users, [user_id])
                  let updated_sub_reddit =
                    SubReddit(..subreddit, users: upd_user_list)
                  dict.insert(
                    subreddit_dict,
                    subreddit_uuid,
                    updated_sub_reddit,
                  )
                }
              }
              actor.send(client, Ok("Joined Subreddit successfully."))
              subreddit_dict
            }
            _ -> {
              actor.send(client, Error("Subreddit does not exist."))
              subreddit_dict
            }
          }

          actor.continue(Directory(..state, subreddits: updated_subreddit_dict))
        }
        _ -> {
          actor.send(client, Error("Invalid User."))
          actor.continue(state)
        }
      }
    }
    LeaveSubReddit(subreddit_uuid, user_principal, client) -> {
      let user_email = user_principal.email
      case dict.get(state.users, user_email) {
        Ok(user) -> {
          let user_id = user.id
          let subreddit_dict = state.subreddits
          let updated_subreddit_dict = case
            dict.get(subreddit_dict, subreddit_uuid)
          {
            Ok(subreddit) -> {
              let users = subreddit.users
              let subreddit_dict = case list.contains(users, user_id) {
                True -> {
                  let upd_user_list =
                    list.filter(users, fn(id) { id != user_id })
                  let updated_sub_reddit =
                    SubReddit(..subreddit, users: upd_user_list)
                  let updated_sub_reddit =
                    dict.insert(
                      subreddit_dict,
                      subreddit_uuid,
                      updated_sub_reddit,
                    )
                }
                False -> subreddit_dict
              }
              actor.send(client, Ok("Left Subreddit successfully"))
              subreddit_dict
            }
            _ -> {
              actor.send(client, Error("Subreddit does not exist."))
              subreddit_dict
            }
          }
          actor.continue(Directory(..state, subreddits: updated_subreddit_dict))
        }
        _ -> {
          io.println("Invalid user.")
          actor.send(client, Error("Invalid User."))
          actor.continue(state)
        }
      }
    }
    CreatePost(subreddit_uuid, body, user_principal, client) -> {
      let user_email = user_principal.email
      let entity_dict = state.entities
      case dict.get(state.users, user_email) {
        Ok(user) -> {
          let user_id = user.id
          let posts_dict = state.posts
          let subreddit_dict = state.subreddits
          let updated_directory = case
            dict.get(subreddit_dict, subreddit_uuid)
          {
            Ok(subreddit) -> {
              let post_entity_cnt =
                dict.get(entity_dict, PostEntity) |> result.unwrap(1)
              let uuid = uuid.v4_string()
              let subreddit_id = subreddit.id
              let created_post =
                Post(
                  id: post_entity_cnt,
                  uuid: uuid,
                  subreddit_id: subreddit_id,
                  author_id: user_id,
                  body: body,
                  upvote: 0,
                  downvote: 0,
                  comments: None,
                )
              let updated_posts_dict =
                dict.insert(posts_dict, uuid, created_post)
              let updated_entity_dict =
                dict.insert(entity_dict, PostEntity, post_entity_cnt + 1)
              actor.send(client, Ok(uuid))
              let updated_directory =
                Directory(
                  ..state,
                  posts: updated_posts_dict,
                  entities: updated_entity_dict,
                )
            }
            _ -> {
              actor.send(client, Error("Subreddit does not exist."))
              state
            }
          }
          actor.continue(updated_directory)
        }
        _ -> {
          actor.send(client, Error("Invalid User."))
          actor.continue(state)
        }
      }
    }
    CreateComment(post_uuid, comment_uuid, body, user_principal, client) -> {
      let user_email = user_principal.email
      let entity_dict = state.entities
      case dict.get(state.users, user_email) {
        Ok(user) -> {
          let user_id = user.id
          let comments_dict = state.comments
          let posts_dict = state.posts
          let updated_directory = case dict.get(posts_dict, post_uuid) {
            Ok(post) -> {
              let comment_entity_cnt =
                dict.get(entity_dict, CommentEntity) |> result.unwrap(1)
              let post_id = post.id
              let comment_id = case comment_uuid {
                Some(comment_uuid) -> {
                  case dict.get(state.comments, comment_uuid) {
                    Ok(comment) -> Some(comment.id)
                    _ -> None
                  }
                }
                _ -> {
                  None
                }
              }
              let uuid = uuid.v4_string()
              let created_comment =
                Comment(
                  id: comment_entity_cnt,
                  uuid: uuid,
                  author_id: user_id,
                  post_id: post_id,
                  parent_comment_id: comment_id,
                  body: body,
                  upvote: 0,
                  downvote: 0,
                )

              let updated_comment_dict =
                dict.insert(comments_dict, uuid, created_comment)
              let updated_entity_dict =
                dict.insert(entity_dict, CommentEntity, comment_entity_cnt + 1)
              actor.send(client, Ok(uuid))
              let updated_directory =
                Directory(
                  ..state,
                  comments: updated_comment_dict,
                  entities: updated_entity_dict,
                )
            }
            _ -> {
              actor.send(client, Error("Invalid Post."))
              state
            }
          }
          actor.continue(updated_directory)
        }
        _ -> {
          io.println("Invalid user.")
          actor.send(client, Error("Invalid User."))
          actor.continue(state)
        }
      }
    }
    Vote(post_uuid, comment_uuid, up, down, user_principal, client) -> {
      let user_email = user_principal.email
      let users = state.users
      case dict.get(users, user_email) {
        Ok(user) -> {
          let user_id = user.id
          let posts_dict = state.posts
          let comments_dict = state.comments
          case dict.get(posts_dict, post_uuid) {
            Ok(post) -> {
              let author_id = post.author_id
              let comment = case comment_uuid {
                Some(comment_uuid) -> {
                  case dict.get(comments_dict, comment_uuid) {
                    Ok(comment) -> Some(comment)
                    _ -> None
                  }
                }
                _ -> None
              }
              let updated_directory = case comment {
                Some(comment) -> {
                  let upvote = comment.upvote
                  let downvote = comment.downvote
                  let updated_comment =
                    Comment(
                      ..comment,
                      upvote: upvote + up,
                      downvote: downvote + down,
                    )
                  let updated_comments_dict =
                    dict.insert(comments_dict, comment.uuid, updated_comment)
                  let updated_directory =
                    Directory(..state, comments: updated_comments_dict)
                }
                _ -> {
                  let upvote = post.upvote
                  let downvote = post.downvote
                  let updated_post =
                    Post(..post, upvote: upvote + up, downvote: downvote + down)
                  let updated_posts_dict =
                    dict.insert(posts_dict, post_uuid, updated_post)
                  let updated_directory =
                    Directory(..state, posts: updated_posts_dict)
                }
              }
              let author =
                dict.values(users)
                |> list.find(fn(user) { user.id == author_id })
              let assert Ok(user) = author
              let updated_user = User(..user, karma: user.karma + up - down)
              let updated_user_dict =
                dict.insert(users, updated_user.email, updated_user)
              let updated_directory =
                Directory(..updated_directory, users: updated_user_dict)
              actor.send(client, Ok("Voted Successfully."))
              actor.continue(updated_directory)
            }
            _ -> {
              actor.send(client, Error("Invalid Post."))
              actor.continue(state)
            }
          }
        }
        _ -> {
          io.println("Invalid user.")
          actor.send(client, Error("Invalid User"))
          actor.continue(state)
        }
      }
    }
    GetFeed(user_principal, client) -> {
      let user_email = user_principal.email
      let users = state.users
      case dict.get(users, user_email) {
        Ok(user) -> {
          let user_id = user.id
          let subreddits = state.subreddits
          let posts = state.posts
          let comments = state.comments
          let subreddits_list = dict.values(subreddits)
          let posts_list = dict.values(posts)
          let comments_list = dict.values(comments)
          let user_subreddit_ids =
            list.filter_map(subreddits_list, fn(subreddit) {
              let users = subreddit.users
              case list.contains(users, user_id) {
                True -> Ok(subreddit.id)
                False -> Error(1)
              }
            })
          let user_posts =
            list.filter(posts_list, fn(post) {
              list.contains(user_subreddit_ids, post.subreddit_id)
            })

          let user_dto_posts =
            list.map(user_posts, fn(post) {
              let post_comments =
                list.filter(comments_list, fn(comment) {
                  comment.post_id == post.id
                })
              let comment_tree = helpers.build_comment_tree(post_comments)
              Post(..post, comments: Some(comment_tree))
            })
          actor.send(client, Ok(user_dto_posts))
          actor.continue(state)
        }
        _ -> {
          actor.send(client, Error("Invalid User."))
          actor.continue(state)
        }
      }
    }
    SendMessage(
      recipient_email,
      sender_subject,
      recipient_subject,
      body,
      user_principal,
    ) -> {
      let email = user_principal.email
      let user_dict = state.users
      let message_dict = state.messages
      let entity_dict = state.entities
      case dict.get(user_dict, email) {
        Ok(user) -> {
          let user_id = user.id
          let updated_directory = case dict.get(user_dict, recipient_email) {
            Ok(recipient_user) -> {
              let id = recipient_user.id
              let uuid = uuid.v4_string()
              let message_entity_cnt =
                dict.get(entity_dict, MessageEntity) |> result.unwrap(1)
              let created_message =
                Message(
                  id: message_entity_cnt,
                  uuid: uuid,
                  sender_id: user_id,
                  recipient_id: id,
                  body: body,
                )
              let updated_message_dict =
                dict.insert(message_dict, uuid, created_message)
              let updated_entity_dict =
                dict.insert(entity_dict, MessageEntity, message_entity_cnt + 1)
              actor.send(
                recipient_subject,
                ReceiveMessageClient(
                  sender_subject,
                  recipient_subject,
                  email,
                  body,
                ),
              )
              let updated_directory =
                Directory(
                  ..state,
                  messages: updated_message_dict,
                  entities: updated_entity_dict,
                )
            }
            _ -> {
              state
            }
          }
          actor.continue(updated_directory)
        }
        _ -> actor.continue(state)
      }
    }
    GetAvailablePostsandComments(client) -> {
      let posts_dict = state.posts
      let post_uuids = dict.keys(posts_dict)
      let comments = dict.values(state.comments)
      let post_comments =
        list.map(post_uuids, fn(post_uuid) {
          let assert Ok(post) = dict.get(posts_dict, post_uuid)
          let filtered_comments =
            list.filter(comments, fn(comment) { comment.post_id == post.id })
            |> list.map(fn(comment) { comment.uuid })
          #(post_uuid, filtered_comments)
        })
      actor.send(client, post_comments)
      actor.continue(state)
    }
    GetAvailableSubreddits(client) -> {
      let subreddits = dict.keys(state.subreddits)
      actor.send(client, subreddits)
      actor.continue(state)
    }
    GetMetrics(client) -> {
      let users = state.users
      let subreddits = state.subreddits
      let posts = state.posts
      let comments = state.comments
      let subreddit_list = dict.values(subreddits)
      let posts_list = dict.values(posts)
      let comments_list = dict.values(comments)
      let users_list = dict.values(state.users)
      let subreddit_metrics =
        list.map(subreddit_list, fn(subreddit) {
          let user_cnt = list.length(subreddit.users)
          let subreddit_posts =
            list.filter_map(posts_list, fn(post) {
              case post.subreddit_id == subreddit.id {
                True -> Ok(post.id)
                False -> Error(Nil)
              }
            })
          let subreddit_comments =
            list.filter(comments_list, fn(comment) {
              list.contains(subreddit_posts, comment.post_id)
            })
          SubRedditMetrics(
            uuid: subreddit.uuid,
            user_cnt: user_cnt,
            posts_cnt: list.length(subreddit_posts),
            comments_cnt: list.length(subreddit_comments),
          )
        })
      let assert Ok(post_with_max_vote_cnt) =
        list.map(posts_list, fn(post) {
          #(post.uuid, post.upvote + int.absolute_value(post.downvote))
        })
        |> list.reduce(fn(acc, current) {
          case current.1 > acc.1 {
            True -> current
            False -> acc
          }
        })

      let assert Ok(user_with_max_posts) =
        list.map(users_list, fn(user) {
          let user_posts =
            list.filter(posts_list, fn(post) { post.author_id == user.id })
          #(user.uuid, list.length(user_posts))
        })
        |> list.reduce(fn(acc, current) {
          case current.1 > acc.1 {
            True -> current
            False -> acc
          }
        })

      let assert Ok(user_with_max_comments) =
        list.map(users_list, fn(user) {
          let user_comments =
            list.filter(comments_list, fn(comment) {
              comment.author_id == user.id
            })
          #(user.uuid, list.length(user_comments))
        })
        |> list.reduce(fn(acc, current) {
          case current.1 > acc.1 {
            True -> current
            False -> acc
          }
        })
      let metrics =
        Metrics(
          subreddit_metrics: subreddit_metrics,
          post_with_max_vote_cnt: post_with_max_vote_cnt,
          user_with_max_posts: user_with_max_posts,
          user_with_max_comments: user_with_max_comments,
        )
      actor.send(client, metrics)
      actor.continue(state)
    }
    GetState -> {
      echo state.users
      echo state.subreddits
      echo state.posts
      echo state.comments
      echo state.entities
      actor.continue(state)
    }
  }
}
