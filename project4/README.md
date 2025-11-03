# Reddit Engine & Client Simulator

**Project Group:** 24  
**Team Members:** Mahanya Kochhar, Akshay Dhawale

## Overview

This project implements a distributed Reddit-like social platform using the actor model in Gleam, demonstrating key principles of concurrent, fault-tolerant system design. The platform provides essential Reddit functionalities with realistic user behavior simulation at scale.

## Features

### Core Functionality
- **User Registration & Authentication**
- **Subreddit Management**
  - Creation and membership management
  - Automatic enrollment in default subreddit (like Reddit's main feed)
- **Content Management**
  - Post creation and retrieval
  - Hierarchical comment threading
  - Structured thread retrieval in user feeds
- **Voting System**
  - Upvote/downvote functionality for posts and comments
  - Karma computation: +1 per upvote, -1 per downvote
- **Direct Messaging**
  - User-to-user messaging with mailbox system
  - Probabilistic reply mechanism

### Architecture Highlights
- **Engine Actor**: Central coordinator managing global state and processing all client events
- **Asynchronous Client Interaction**: Non-blocking message-passing coordination
- **Simulator**: Generates multiple client actors with configurable TTL to model active/disconnected users
- **Root Client Actor**: Initializes default subreddit ensuring common interaction space

## User Distribution Model

The system implements a **Zipf distribution** to simulate realistic community participation patterns, where popular subreddits attract disproportionately more users.

### Distribution Formula

For subreddit rank `r`:
```
weight_r = 1/r
prob_r = weight_r / total_weight
```

### Example Distribution (5 Subreddits)

| Rank | Weight | Probability |
|------|--------|-------------|
| 1    | 1.000  | 43.8%       |
| 2    | 0.500  | 21.9%       |
| 3    | 0.333  | 14.6%       |
| 4    | 0.250  | 10.9%       |
| 5    | 0.200  | 8.7%        |

This mirrors real-world social platforms where a few communities dominate engagement.

## Usage

### Running the Simulator
```bash
gleam run <no_users> <no_subreddits>
```

**Default values** (if parameters not provided):
- Users: 10
- Subreddits: 5

### Example Commands
```bash
# Run with default settings
gleam run

# Custom simulation
gleam run 1000 10

# Large-scale test
gleam run 30000 30
```

## Performance Results

The system has been successfully tested with:
- **Up to 30,000 users**
- **30 subreddits**
- Demonstrated efficient message handling and stability under heavy load

### Sample Metrics (100 Users, 6 Subreddits)

| Subreddit UUID | Users | Posts | Comments |
|----------------|-------|-------|----------|
| 113eaad7-...   | 101   | 125   | 128      |
| 1b03bebe-...   | 15    | 125   | 141      |
| 3fefc87d-...   | 14    | 117   | 109      |
| bd1397cd-...   | 23    | 148   | 115      |
| d39034e7-...   | 17    | 128   | 129      |
| db4f0615-...   | 55    | 131   | 111      |

### Key Observations
- **Heavy-tailed participation**: Base subreddit attracts majority of users (101/100 including root)
- **Consistent engagement**: Comment-to-post ratio ~1:1 across all subreddits
- **Active smaller communities**: Smaller subreddits maintain high activity through concurrent actions
- **Distributed activity**: Post counts range 117-148 despite varying user counts

## Design Principles

This project demonstrates effective application of distributed systems concepts:

-  **Concurrency**: Actor-model enables parallel user interactions
-  **Isolation**: Independent actor state prevents interference
-  **Message-Passing Coordination**: Asynchronous communication patterns
-  **Fault Tolerance**: Resilient to user disconnections (TTL-based lifecycle)
-  **Scalability**: Tested at 30K users with stable performance

## Technical Stack

- **Language**: Gleam
- **Concurrency Model**: Actor-based architecture
- **Distribution Pattern**: Zipf distribution for realistic modeling

## Project Scope Achievement

 Distributed social platform with Reddit-like functionality  
 Scalable actor-model implementation  
 Realistic user behavior simulation  
 Hierarchical content structures  
 Large-scale performance validation (30K users)  
 Configurable simulation parameters  

## Conclusion

This Reddit clone successfully demonstrates how actor-model concurrency and distributed design principles can build scalable, resilient social platforms that mirror real-world engagement patterns. The system efficiently handles concurrent operations, maintains consistent state, and supports realistic community dynamics at scale.