import gleam/bit_array
import gleam/crypto
import gleam/dict.{type Dict}
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/result
import models.{
  type Directory, type Entity, type Post, type SubReddit, type User,
  type UserPrincipal, Directory, Post, PostEntity, SubReddit, SubRedditEntity,
  User, UserEntity, UserPrincipal,
}
import youid/uuid

pub type Action {
  RegisterUser(User)
  CreateSubReddit(SubReddit, UserPrincipal)
  JoinSubReddit(String, UserPrincipal)
  CreatePost(String, Post, UserPrincipal)
}

pub fn handle_action(
  state: Directory,
  action: Action,
) -> actor.Next(Directory, Action) {
  case action {
    RegisterUser(user) -> {
      let entity_dict = state.entities
      let user_dict = state.users
      let email = user.email
      let assert Some(password) = user.password
      let is_already_registered = dict.has_key(user_dict, email)
      let updated_directory = case is_already_registered {
        True -> {
          io.println("Email " <> email <> " is already registered.")
          state
        }
        False -> {
          let user_entity_cnt =
            dict.get(entity_dict, UserEntity) |> result.unwrap(1)
          let created_user =
            User(
              id: Some(user_entity_cnt),
              uuid: Some(uuid.v4_string()),
              email: email,
              stored_password: Some(crypto.hash(
                crypto.Sha256,
                bit_array.from_string(password),
              )),
              password: None,
            )
          let updated_user_dict = dict.insert(user_dict, email, created_user)
          let updated_entity_dict =
            dict.insert(entity_dict, UserEntity, user_entity_cnt + 1)
          Directory(
            ..state,
            users: updated_user_dict,
            entities: updated_entity_dict,
          )
        }
      }
      actor.continue(updated_directory)
    }
    CreateSubReddit(subreddit, user_principal) -> {
      let user_email = user_principal.email
      case dict.get(state.users, user_email) {
        Ok(user) -> {
          let assert Some(user_id) = user.id
          let entity_dict = state.entities
          let subreddit_dict = state.subreddits
          let name = subreddit.name
          let subreddit_entity_cnt =
            dict.get(entity_dict, SubRedditEntity) |> result.unwrap(1)
          let uuid = uuid.v4_string()
          let created_subreddit =
            SubReddit(
              id: Some(subreddit_entity_cnt),
              uuid: Some(uuid),
              name: name,
              title: subreddit.title,
              created_by: Some(user_id),
              users: Some([user_id]),
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
          actor.continue(updated_directory)
        }
        _ -> {
          io.println("Invalid user.")
          actor.continue(state)
        }
      }
    }
    JoinSubReddit(subreddit_uuid, user_principal) -> {
      let user_email = user_principal.email
      case dict.get(state.users, user_email) {
        Ok(user) -> {
          let assert Some(user_id) = user.id
          let subreddit_dict = state.subreddits
          let updated_subreddit_dict = case
            dict.get(subreddit_dict, subreddit_uuid)
          {
            Ok(subreddit) -> {
              let assert Some(users) = subreddit.users
              case list.contains(users, user_id) {
                True -> {
                  subreddit_dict
                }
                False -> {
                  let upd_user_list = list.append(users, [user_id])
                  let updated_sub_reddit =
                    SubReddit(..subreddit, users: Some(upd_user_list))
                  dict.insert(
                    subreddit_dict,
                    subreddit_uuid,
                    updated_sub_reddit,
                  )
                }
              }
            }
            _ -> {
              subreddit_dict
            }
          }
          actor.continue(Directory(..state, subreddits: updated_subreddit_dict))
        }
        _ -> {
          io.println("Invalid user.")
          actor.continue(state)
        }
      }
    }
    CreatePost(subreddit_uuid, post, user_principal) -> {
      let user_email = user_principal.email
      let entity_dict = state.entities
      case dict.get(state.users, user_email) {
        Ok(user) -> {
          let assert Some(user_id) = user.id
          let posts_dict = state.posts
          let subreddit_dict = state.subreddits
          let updated_directory = case
            dict.get(subreddit_dict, subreddit_uuid)
          {
            Ok(subreddit) -> {
              let post_entity_cnt =
                dict.get(entity_dict, PostEntity) |> result.unwrap(1)
              let uuid = uuid.v4_string()
              let assert Some(subreddit_id) = subreddit.id
              let created_post =
                Post(
                  ..post,
                  id: Some(post_entity_cnt),
                  uuid: Some(uuid),
                  subreddit_id: Some(subreddit_id),
                  author_id: Some(user_id),
                )
              let updated_posts_dict =
                dict.insert(posts_dict, uuid, created_post)
              let updated_entity_dict =
                dict.insert(entity_dict, PostEntity, post_entity_cnt + 1)
              let updated_directory =
                Directory(
                  ..state,
                  posts: updated_posts_dict,
                  entities: updated_entity_dict,
                )
            }
            _ -> {
              state
            }
          }
          actor.continue(updated_directory)
        }
        _ -> {
          actor.continue(state)
        }
      }
    }
  }
}
