import gleam/bit_array
import gleam/crypto
import gleam/dict.{type Dict}
import gleam/io
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/result
import models.{
  type Directory, type Entity, type SubReddit, type User, Directory, SubReddit,
  User, UserEntity,
}
import youid/uuid

pub type Action {
  RegisterUser(User)
  CreateSubReddit(SubReddit)
  //   JoinSubReddit
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
    CreateSubReddit(subreddit) -> {
      let subreddit_dict = state.subreddits
      let name = subreddit.name
      let is_already_present = dict.has_key(subreddit_dict, name)
      case is_already_present {
        True -> {
          io.println(
            "SubReddit alreay exists. You should consider joining the same.",
          )
        }
        False -> {
          todo
        }
      }
    }
  }
}
