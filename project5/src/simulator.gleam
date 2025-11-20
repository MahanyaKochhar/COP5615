// import clients
// import engine
// import gleam/dict
// import gleam/erlang/process
// import gleam/int
// import gleam/io
// import gleam/list
// import gleam/option.{None, Some}
// import gleam/otp/actor
// import gleam/time/timestamp
// import prng/random

// const call_milliseconds = 5000

// pub fn simulate_root_user(client_subject: process.Subject(engine.Request)) {
//   let dict = dict.new()
//   let email = "kochharm@ufl.edu"
//   let password = "kochharm"
//   let subreddit_name = "University of Florida"
//   let post_name = "Distributed Operating System Principles"
//   let comment_name = "Deadline for Project 2 is Nov 2 midnight."
//   let child_comment_name = "Please use Gleam and the actor model only."
//   let email =
//     actor.call(client_subject, call_milliseconds, engine.RegisterClient(
//       email,
//       password,
//       _,
//     ))

//   let updated_dict = case email {
//     Ok(email) -> {
//       let subreddit_uuid =
//         actor.call(
//           client_subject,
//           call_milliseconds,
//           engine.CreateSubRedditClient(subreddit_name, _),
//         )
//       case subreddit_uuid {
//         Ok(subreddit_uuid) -> {
//           let updated_dict = dict.insert(dict, "subreddit_uuid", subreddit_uuid)
//           let post_uuid =
//             actor.call(
//               client_subject,
//               call_milliseconds,
//               engine.CreatePostClient(subreddit_uuid, post_name, _),
//             )
//           let updated_dict = case post_uuid {
//             Ok(post_uuid) -> {
//               let updated_dict =
//                 dict.insert(updated_dict, "post_uuid", post_uuid)
//               let comment_uuid =
//                 actor.call(
//                   client_subject,
//                   call_milliseconds,
//                   engine.CreateCommentClient(post_uuid, None, comment_name, _),
//                 )
//               let updated_dict = case comment_uuid {
//                 Ok(comment_uuid) -> {
//                   let updated_dict =
//                     dict.insert(updated_dict, "comment_uuid", comment_uuid)
//                   let child_comment_uuid =
//                     actor.call(
//                       client_subject,
//                       call_milliseconds,
//                       engine.CreateCommentClient(
//                         post_uuid,
//                         Some(comment_uuid),
//                         child_comment_name,
//                         _,
//                       ),
//                     )
//                   let updated_dict = case child_comment_uuid {
//                     Ok(child_comment_uuid) -> {
//                       dict.insert(
//                         updated_dict,
//                         "child_comment_uuid",
//                         child_comment_uuid,
//                       )
//                     }
//                     _ -> updated_dict
//                   }
//                 }
//                 _ -> updated_dict
//               }
//               updated_dict
//             }
//             _ -> {
//               io.println("Post not created.")
//               dict
//             }
//           }
//           updated_dict
//         }
//         _ -> {
//           io.println("Subreddit not created.")
//           dict
//         }
//       }
//     }
//     _ -> {
//       io.println("User not created.")
//       dict
//     }
//   }
//   updated_dict
// }

// pub fn create_subreddits(
//   user_subjects: List(process.Subject(engine.Request)),
//   subreddits: Int,
// ) {
//   let subreddit_names =
//     list.map(list.range(1, subreddits), fn(no) {
//       let str = "Simulated Subreddit " <> int.to_string(no)
//     })
//   let assert Ok(random_user_subject) =
//     list.sample(user_subjects, 1) |> list.first
//   let subreddit_uuids =
//     list.map(subreddit_names, fn(subreddit_name) {
//       let assert Ok(subreddit_uuid) =
//         actor.call(
//           random_user_subject,
//           call_milliseconds,
//           engine.CreateSubRedditClient(subreddit_name, _),
//         )
//       subreddit_uuid
//     })

//   subreddit_uuids
// }

// pub fn zipf_distribution(n: Int) {
//   let alpha = 1.0
//   let zipf_weights =
//     list.map(list.range(1, n), fn(element) {
//       1.0 /. { alpha *. int.to_float(element) }
//     })
//   let sum = list.fold(zipf_weights, 0.0, fn(acc, weight) { acc +. weight })

//   let normalized_zipf_weights =
//     list.map(zipf_weights, fn(weight) { weight /. sum })
//   normalized_zipf_weights
// }

// pub fn join_subreddits_zipf_distribution(
//   user_subjects: List(process.Subject(engine.Request)),
//   subreddit_uuids: List(String),
// ) {
//   let generator = random.float(0.0, 1.0)
//   let zipf_distribution = zipf_distribution(list.length(subreddit_uuids))
//   let uuid_weight_list =
//     list.map2(subreddit_uuids, zipf_distribution, fn(uuid, weight) {
//       #(uuid, weight)
//     })
//   io.println("SubReddit UUIDs Zipf Distribution Probabilities -> ")
//   echo uuid_weight_list
//   list.each(user_subjects, fn(user_subject) {
//     list.each(uuid_weight_list, fn(uuid_weight) {
//       let uuid = uuid_weight.0
//       let weight = uuid_weight.1
//       let random_selection = random.random_sample(generator)
//       case random_selection <=. weight {
//         True -> {
//           actor.call(
//             user_subject,
//             call_milliseconds,
//             engine.JoinSubRedditClient(uuid, _),
//           )
//           Nil
//         }
//         _ -> {
//           Nil
//         }
//       }
//     })
//   })
// }

// pub fn simulate_users(
//   engine_subject: process.Subject(engine.Action),
//   inputs: #(Int, Int),
//   updated_dict: dict.Dict(String, String),
// ) {
//   let generator = random.float(10.0, 20.0)
//   let assert Ok(base_subreddit_uuid) = dict.get(updated_dict, "subreddit_uuid")
//   let user_subjects =
//     list.map(list.range(1, inputs.0), fn(no) {
//       let client_ttl = random.random_sample(generator)
//       let assert Ok(user_actor) =
//         actor.new(#(engine_subject, "", client_ttl))
//         |> actor.on_message(clients.handle_request)
//         |> actor.start
//       let email = "Simulated User " <> int.to_string(no) <> " Email"
//       let password = "Simulated User " <> int.to_string(no) <> " Password"
//       let user_subject = user_actor.data
//       let email =
//         actor.call(user_subject, call_milliseconds, engine.RegisterClient(
//           email,
//           password,
//           _,
//         ))
//       actor.call(user_subject, call_milliseconds, engine.JoinSubRedditClient(
//         base_subreddit_uuid,
//         _,
//       ))
//       user_subject
//     })
//   user_subjects
// }

// pub type Activity {
//   Post
//   Vote
//   Comment
//   Feed
// }

// pub fn get_activity(random_int: Int) {
//   case random_int % 4 {
//     0 -> Post
//     1 -> Vote
//     2 -> Comment
//     _ -> Feed
//   }
// }

// pub fn pick_post_comment(posts_comments: List(#(String, List(String)))) {
//   let assert Ok(random_post) = list.sample(posts_comments, 1) |> list.first
//   let post = random_post.0
//   let comments = random_post.1
//   let generator = random.choose(0, 1)
//   let choice = random.random_sample(generator)
//   let upvote = random.random_sample(generator)
//   let picked_comment = case choice {
//     1 -> {
//       let random_comment = list.sample(comments, 1) |> list.first
//       case random_comment {
//         Ok(random_comment) -> Some(random_comment)
//         _ -> None
//       }
//     }
//     _ -> {
//       None
//     }
//   }
//   let downvote = case upvote {
//     1 -> 0
//     _ -> 1
//   }
//   #(post, picked_comment, upvote, downvote)
// }

// pub fn simulate_activity(
//   user_subjects: List(process.Subject(engine.Request)),
//   start_time: Float,
//   stop_simulation: Bool,
// ) {
//   case stop_simulation {
//     True -> {
//       io.println("Terminating Simulation.")
//       io.println("***********************")
//       None
//     }
//     False -> {
//       process.sleep(1000)
//       let assert Ok(random_user_subject) =
//         list.sample(user_subjects, 1) |> list.first
//       let generator = random.int(0, 200)
//       let random_int = random.random_sample(generator)
//       let activity = get_activity(random_int)
//       io.println("Simulation Activity Selected -> ")
//       echo activity
//       case activity {
//         Post -> {
//           let subreddits =
//             actor.call(
//               random_user_subject,
//               call_milliseconds,
//               engine.GetAvailableSubredditsClient,
//             )
//           let assert Ok(random_subreddit) =
//             list.sample(subreddits, 1) |> list.first
//           let assert Ok(post_uuid) =
//             actor.call(
//               random_user_subject,
//               call_milliseconds,
//               engine.CreatePostClient(random_subreddit, "Random Post", _),
//             )
//           io.println(
//             "Post " <> post_uuid <> "created in SubReddit " <> random_subreddit,
//           )
//           Nil
//         }
//         Vote -> {
//           let posts_comments =
//             actor.call(
//               random_user_subject,
//               call_milliseconds,
//               engine.GetAvailablePostsandCommentsClient,
//             )
//           let post_comment_vote = pick_post_comment(posts_comments)
//           actor.call(random_user_subject, call_milliseconds, engine.VoteClient(
//             post_comment_vote.0,
//             post_comment_vote.1,
//             post_comment_vote.2,
//             post_comment_vote.3,
//             _,
//           ))
//           case post_comment_vote.1 {
//             Some(res) ->
//               io.println(
//                 "Voted Successfully on comment "
//                 <> res
//                 <> " in post "
//                 <> post_comment_vote.0,
//               )
//             _ ->
//               io.println("Voted Successfully on post " <> post_comment_vote.0)
//           }
//           Nil
//         }
//         Comment -> {
//           let posts_comments =
//             actor.call(
//               random_user_subject,
//               call_milliseconds,
//               engine.GetAvailablePostsandCommentsClient,
//             )
//           let post_comment_vote = pick_post_comment(posts_comments)
//           actor.call(
//             random_user_subject,
//             call_milliseconds,
//             engine.CreateCommentClient(
//               post_comment_vote.0,
//               post_comment_vote.1,
//               "Random Comment",
//               _,
//             ),
//           )
//           case post_comment_vote.1 {
//             Some(res) ->
//               io.println(
//                 "Commented Successfully on comment "
//                 <> res
//                 <> " in post "
//                 <> post_comment_vote.0,
//               )
//             _ ->
//               io.println(
//                 "Commented Successfully on post " <> post_comment_vote.0,
//               )
//           }
//           Nil
//         }
//         Feed -> {
//           let assert Ok(result) =
//             actor.call(
//               random_user_subject,
//               call_milliseconds,
//               engine.GetFeedClient,
//             )
//           io.println(" User Generated Feed is -> ")
//           echo result
//           Nil
//         }
//       }

//       let res =
//         list.map(user_subjects, fn(user_subject) {
//           let ttl =
//             actor.call(user_subject, call_milliseconds, engine.GetTTLInfoClient)
//           let current_time =
//             timestamp.system_time() |> timestamp.to_unix_seconds()
//           current_time >=. ttl +. start_time
//         })
//       let total_count = list.count(res, fn(ele) { ele == True })
//       let stop_simulation = total_count >= list.length(user_subjects) - 1
//       simulate_activity(user_subjects, start_time, stop_simulation)
//       None
//     }
//   }
// }
