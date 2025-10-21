// model.gleam - Core type definitions for the Reddit engine

import gleam/option.{type Option}

// Basic types
pub type UserId =
  Int

pub type Username =
  String

pub type SubredditId =
  Int

pub type PostId =
  Int

pub type CommentId =
  Int

pub type Timestamp =
  Int

// User model
pub type User {
  User(
    id: UserId,
    username: Username,
    created_at: Timestamp,
    karma: Int,
    subscribed: List(SubredditId),
  )
}

// Subreddit model
pub type Subreddit {
  Subreddit(
    id: SubredditId,
    name: String,
    member_count: Int,
    post_ids: List(PostId),
    created_at: Timestamp,
  )
}

// Post model
pub type Post {
  Post(
    id: PostId,
    author_id: UserId,
    subreddit_id: SubredditId,
    title: String,
    body: String,
    created_at: Timestamp,
    score: Int,
    upvotes: Int,
    downvotes: Int,
    comment_count: Int,
    repost_of: Option(PostId),
  )
}

// Comment model
pub type Comment {
  Comment(
    id: CommentId,
    post_id: PostId,
    author_id: UserId,
    parent_id: Option(CommentId),
    body: String,
    created_at: Timestamp,
    children: List(CommentId),
    score: Int,
    upvotes: Int,
    downvotes: Int,
  )
}

// Vote model
pub type TargetType {
  PostTarget
  CommentTarget
}

pub type Vote {
  Vote(voter_id: UserId, target_type: TargetType, target_id: Int, value: Int)
}

pub type VoteKey {
  VoteKey(target_type: TargetType, target_id: Int, voter_id: UserId)
}

// Direct message model
pub type DirectMessage {
  DirectMessage(
    id: Int,
    from_id: UserId,
    to_id: UserId,
    body: String,
    created_at: Timestamp,
    read: Bool,
  )
}

// Feed types
pub type FeedKind {
  New
  Hot
  Top
}

// Engine messages (API)
pub type EngineMsg {
  RegisterUser(username: String)
  CreateSubreddit(name: String, owner_id: UserId)
  JoinSubreddit(user_id: UserId, subreddit_id: SubredditId)
  LeaveSubreddit(user_id: UserId, subreddit_id: SubredditId)
  CreatePost(
    author_id: UserId,
    subreddit_id: SubredditId,
    title: String,
    body: String,
  )
  CreateComment(
    author_id: UserId,
    post_id: PostId,
    parent_id: Option(CommentId),
    body: String,
  )
  VoteMsg(voter_id: UserId, target_type: TargetType, target_id: Int, value: Int)
  GetFeed(
    user_id: Option(UserId),
    subreddit_id: Option(SubredditId),
    kind: FeedKind,
    limit: Int,
  )
  GetPost(post_id: PostId)
  GetComments(post_id: PostId)
  GetUser(user_id: UserId)
  GetUserByName(username: String)
  GetSubreddit(subreddit_id: SubredditId)
  GetSubredditByName(name: String)
  SendDirectMessage(from_id: UserId, to_id: UserId, body: String)
  GetDirectMessages(user_id: UserId)
  GetMetrics
}

// Response types
pub type EngineResponse {
  UserCreated(user: User)
  SubredditCreated(subreddit: Subreddit)
  PostCreated(post: Post)
  CommentCreated(comment: Comment)
  DirectMessageSent(dm: DirectMessage)
  JoinedSubreddit
  LeftSubreddit
  VoteRegistered
  FeedResult(posts: List(Post))
  PostResult(post: Post)
  CommentsResult(comments: List(Comment))
  UserResult(user: User)
  SubredditResult(subreddit: Subreddit)
  DirectMessagesResult(messages: List(DirectMessage))
  MetricsResult(metrics: Metrics)
  Error(reason: EngineError)
}

// Error types
pub type EngineError {
  UserNotFound
  UserAlreadyExists
  SubredditNotFound
  SubredditAlreadyExists
  PostNotFound
  CommentNotFound
  InvalidVoteValue
  InvalidInput(String)
  NotSubscribed
  AlreadySubscribed
}

// Metrics
pub type Metrics {
  Metrics(
    total_users: Int,
    total_subreddits: Int,
    total_posts: Int,
    total_comments: Int,
    total_votes: Int,
  )
}
