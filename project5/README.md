# Reddit Engine API Interface

**Project Group:** 24  
**Team Members:** Akshay Dhawale, Mahanya Kochhar

**Demo Video URL:** [Youtube URL](https://youtu.be/qG3naaFvQ2s)

## Server Overview

This project implements the REST API Interface for the Reddit Engine designed in Project 4 Part 1. Along with that, it implements a REST API Client that uses the REST API endpoints and makes requests to the server endpoints.

We have used Mist and Wisp packages of the Gleam programming language. Mist and Wisp are two core components used for building web applications in the Gleam programming language. They work together to handle HTTP requests and serve web content.

**Mist** is the low-level web server itself, written entirely in Gleam. Its job is to listen on a specific port, handle the raw network connections, and deal with the basic mechanics of the HTTP protocol. It is the engine that keeps your web application running and accessible. Mist further is utilized directly to handle the necessary low-level primitives for establishing and managing all connections including persistent, bidirectional full-duplex WebSocket connections.

**Wisp** is the web framework that sits on top of Mist. It provides a higher-level, more developer-friendly structure for managing stateless request/response web cycles fundamental to REST. Wisp handles tasks like routing, middleware, and request/response handling.


All the state including the message state is stored in the engine actor that drives the entire application and maintains persistence of data. This engine actor coordinates the entire application and serves as a datastore in some sense.

### Client Overview

The client uses the Gleam HTTPC package. `gleam_httpc` is the primary HTTP client library for making outbound network requests in Gleam when running on the Erlang/BEAM virtual machine.

The client implementation calls the respective implemented API endpoints to:

1. Register users
2. Create subreddits
3. Join or leave subreddits
4. Create posts
5. Comment on posts
6. Comment on comments (hierarchical commenting)
7. Vote on posts or comments
8. Retrieve user profile (karma)
9. Retrieve user feed
10. View inbox messages

## REST APIs
As part of this project , we have designed a RESTful API interface for the Reddit Engine implemented in Part 1.

A REST API (Representational State Transfer Application Programming Interface) is an architectural style for networked applications that treats server-side data entities, known as resources, as unique objects accessible via standardized URIs. Interaction with these resources is stateless and is governed by standard HTTP methods (like GET for reading, POST for creating, PUT for full updates, and DELETE for removal) to perform the basic CRUD operations. This design principle ensures a uniform interface and decouples the client from the server.


The project implements a RESTful API leveraging a clear, hierarchical URI structure to manage the core resources: users, subreddits, posts, and comments. Endpoints are designed to reflect resource relationships and specific actions. The routing system utilizes hierarchical URIs, clearly demonstrating resource relationships (e.g., a comment belonging to a post). Dedicated endpoints have been established to handle fundamental operations such as resource creation, membership management, viewing feeds, and modifying state via voting, ensuring clear separation of concerns and adherence to stateless interaction standards.

Specifically, we have implemented Create (POST method) for registering users, creating subreddits, posting and commenting on subreddits, Read (Get Method) for retreiving user messages inbox and user feed.

The API paths leverage a strong hierarchical structure and are anchored by UUIDs (Universally Unique Identifiers) for all resources. This design ensures that every resource is globally unique and reflects accurate ownership relationships; specifically, posts belong to a subreddit, comments belong to a post, and the routing is flexible enough to manage both top-level and nested comments for threaded discussions.

The API is served by the Mist web server, accessible on localhost via Port 8000. All incoming REST requests are processed by the Wisp framework, which is also utilized to implement the system's logging strategy, ensuring every request is properly recorded using Wisp's built-in logging utilities. We have further added logging for the responses received in the client to view in the terminal.

API specification:
The API strictly adheres to a JSON-only data format for both request and response bodies. For authenticated endpoints, security is enforced by requiring a client-provided x-email header; otherwise, the request is rejected as unauthorized. Standard HTTP Status Codes are used for clear communication: 201 for successful resource creation, 200 for successful read/modification responses, and various 400-level codes (e.g., 400 Bad Request) to signal client errors such as invalid input or malformed JSON payloads.

## API Endpoints

### 1. Create Subreddit
- **Method:** POST
- **Endpoint:** `/api/subreddit`
- **Headers:** `x-email: <user email>`
- **Body:**
```json
{
  "name": "University of Florida"
}
```

### 2. Register User
- **Method:** POST
- **Endpoint:** `/api/user`
- **Body:**
```json
{
  "email": "mahannya.kochhar@gmail.com",
  "password": "mk"
}
```

### 3. Join Subreddit
- **Method:** POST
- **Endpoint:** `/api/user/{user_id}/subreddit/{subreddit_id}`
- **Headers:** `x-email: <user email>`

### 4. Leave Subreddit
- **Method:** DELETE
- **Endpoint:** `/api/user/subreddit/{subreddit_id}`
- **Headers:** `x-email: <user email>`

### 5. Create Post
- **Method:** POST
- **Endpoint:** `/api/subreddit/{subreddit_id}/post`
- **Headers:** `x-email: <user email>`
- **Body:**
```json
{
  "body": "Distributed Operating System Principles"
}
```

### 6. Create Comment (on Post)
- **Method:** POST
- **Endpoint:** `/api/post/{post_id}/comment`
- **Headers:** `x-email: <user email>`
- **Body:**
```json
{
  "body": "Use Gleam, REST APIs and Actor Model only. If possible, use Websockets."
}
```

### 7. Create Comment Reply (Comment of Comment)
- **Method:** POST
- **Endpoint:** `/api/post/{post_id}/comment/{comment_id}`
- **Headers:** `x-email: <user email>`
- **Body:**
```json
{
  "body": "Use Gleam, REST APIs and Actor Model only. If possible, use Websockets."
}
```

### 8. Get Feed
- **Method:** GET
- **Endpoint:** `/api/user/feed`
- **Headers:** `x-email: <user email>`

### 9. Vote on Post
- **Method:** POST
- **Endpoint:** `/api/post/{post_id}/vote`
- **Headers:** `x-email: <user email>`
- **Body:**
```json
{
  "up": 0,
  "down": 2
}
```

### 10. Vote on Comment
- **Method:** POST
- **Endpoint:** `/api/post/{post_id}/comment/{comment_id}/vote`
- **Headers:** `x-email: <user email>`
- **Body:**
```json
{
  "up": 0,
  "down": 1
}
```

### 11. Get Inbox
- **Method:** GET
- **Endpoint:** `/api/user/inbox`
- **Headers:** `x-email: <user email>`

### 12. Not Found (Test Endpoint)
- **Method:** GET
- **Endpoint:** `/api/call`
- **Headers:** `x-email: <user email>`


## Run the Server

```
cd project5
gleam dev
```

## Run the Client

```
cd project5-client
gleam run
```


## Web Socket Implementation

Additonally, we have leveraged the Mist low level server and built a WebSocket application in Gleam,where we have bypassed Wisp's routing entirely for the specific endpoint and have interacted directly with Mist's WebSocket functions to implement the messaging functionality:
Mist specifically provides the functions to:

1. Accept the connection.

2. Send messages to the client.

3. Receive messages from the client.

4. Close the connection.

We have exposed a REST API endpoint to (/inbox) to retrieve a user's inbox to verify the websocket and messaging functionality implementation.

The Postman WebSocket client is used to validate the real-time, stateful behavior of our chat service and we have demonstrated the same in our demo.

1. Connection Integrity
Establishment: Postman confirms that it can successfully establish and maintain a persistent, full-duplex WebSocket connection to our Mist server.

2. Message Format and Delivery
Data Format: We send and receive messages through the Postman interface, confirming that the data transferred (the frames) adheres to the expected JSON structure you've defined for chat messages.

Two-Way Flow: Using two separate Postman connections, we  validate end-to-end message delivery and latency. This confirms our server logic can route a message received from Connection A out to Connection B in real time.


--- 

The project thus successfully developed a full-stack backend service for a Reddit application, built using the Gleam language on the BEAM virtual machine.


