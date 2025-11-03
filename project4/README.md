


1. Things done
- Reddit Engine implemented completely with all functionality. List all functionality
- Engine Actor managing entire state. It acts as a central data store processing all client sent events. Each client sends events to this engine and engine succesfully serves the request and updates its data store. 
- Simulator implemented with multiple actor clients with time to live for each actor client, post which it becomes disconnected.
- Root Client Actor who creates a root subreddit,post within it,comment within it and each user who joins is a member of this subreddit by default. Like in real Reddit functionality. / Reddit type. This subreddit has all users as subscribers
- Karma computed with simple calculation . Each upvote is +1 and downvote is -1 to overall user karma. Posts and comments have their upvote , downvote cnt to mirror real Reddit like UI. Both posts and comments votes contribute to user karma.
- Messaging functionality implemented. A user can send a message to another user's mailbox and can either receive a reply or not with a certain probability distribution.
- Zipf distribution for no of users in each subreddit as per  logic shared in evening with you.
- Hierarchial comments with comment chaining and commenting on comments possible. On viewing user feed, appropriate data transfer object shared with comment hierarchy followed.

- Performance Metrics for each subreddit(no of users, posts,comments)
- Overall Performance (User with max posts,posts with max votes, user with max comments) . Similar performance metrics can be implemented in the future.

- Specify max numbers you can run for


To run code with params:
gleam run no_users no_subreddits
Both should be integers. If not there are default values of 10 users and 5 subreddits.