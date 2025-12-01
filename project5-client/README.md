## Content:

### Packages Used:

We have used Mist and Wisp packages of the Gleam programming language.
Mist and Wisp are two core components used for building web applications in the Gleam programming language. They work together to handle HTTP requests and serve web content.

Mist is the low-level web server itself, written entirely in Gleam. Its job is to listen on a specific port, handle the raw network connections, and deal with the basic mechanics of the HTTP protocol. It is the engine that keeps your web application running and accessible. Mist further is utilized directly to handle the necessary low-level primitives for establishing and managing all connections including persistent, bidirectional full-duplex WebSocket connections. It manages the long-lived, stateful connection between the server and the client. Mist exposes the necessary low-level primitives for sending and receiving WebSocket frames (the individual data packets used in the WebSocket protocol).


Wisp is the web framework that sits on top of Mist. It provides a higher-level, more developer-friendly structure for managing stateless request/response web cycles fundamental to REST (Representational State Transfer). Wisp handles things like:
1. Routing: Matching incoming requests to the correct handler function.
2. Middleware: Allowing you to run common tasks (like logging, authentication, or serving static files) before or after a request is handled.
3. Request/Response handling: Providing easy-to-use types and functions for working with HTTP requests (like extracting body, headers, and parameters) and generating responses (like HTML or JSON).

### REST API Designed

As part of this project , we have designed a RESTful API interface for the Reddit Engine implemented in Part 1.


A REST API (Representational State Transfer Application Programming Interface) is an architectural style for networked applications that treats server-side data entities, known as resources, as unique objects accessible via standardized URIs. Interaction with these resources is stateless and is governed by standard HTTP methods (like GET for reading, POST for creating, PUT for full updates, and DELETE for removal) to perform the basic CRUD operations. This design principle ensures a uniform interface and decouples the client from the server.


The project implements a RESTful API leveraging a clear, hierarchical URI structure to manage the core resources: users, subreddits, posts, and comments. Endpoints are designed to reflect resource relationships and specific actions. The routing system utilizes hierarchical URIs, clearly demonstrating resource relationships (e.g., a comment belonging to a post). Dedicated endpoints have been established to handle fundamental operations such as resource creation, membership management, viewing feeds, and modifying state via voting, ensuring clear separation of concerns and adherence to stateless interaction standards.

Specifically, we have implemented Create (POST method) for registering users, creating subreddits, posting and commenting on subreddits, Read (Get Method) for retreiving user messages inbox and user feed.

The API paths leverage a strong hierarchical structure and are anchored by UUIDs (Universally Unique Identifiers) for all resources. This design ensures that every resource is globally unique and reflects accurate ownership relationships; specifically, posts belong to a subreddit, comments belong to a post, and the routing is flexible enough to manage both top-level and nested comments for threaded discussions.

The API is served by the Mist web server, accessible on localhost via Port 8000. All incoming REST requests are processed by the Wisp framework, which is also utilized to implement the system's logging strategy, ensuring every request is properly recorded using Wisp's built-in logging utilities. We have further added logging for the responses received in the client to view in the terminal. 



API specification:
The API strictly adheres to a JSON-only data format for both request and response bodies. For authenticated endpoints, security is enforced by requiring a client-provided x-email header; otherwise, the request is rejected as unauthorized. Standard HTTP Status Codes are used for clear communication: 201 for successful resource creation, 200 for successful read/modification responses, and various 400-level codes (e.g., 400 Bad Request) to signal client errors such as invalid input or malformed JSON payloads.


### Web Socket Implementation

Additonally, we have leveraged the Mist low level server and built a WebSocket application in Gleam,where we have bypassed Wisp's routing entirely for the specific endpoint and have interacted directly with Mist's WebSocket functions to implement the messaging functionality:
Mist specifically provides the functions to

1. Accept the connection.

2. Send messages to the client.

3. Receive messages from the client.

4. Close the connection.

 We have exposed a REST API endpoint to (/inbox) to retrieve a user's inbox to verify the websocket and messaging functionality implementation.



All the state including the message state is stored in the engine actor that drives the entire application and maintains persistence of data. This engine actor coordinates the entire application and serves as a datastore in some sense.





### Client Implementation:

The client uses the Gleam HTTPC package.
gleam_httpc (often referred to simply as httpc in Gleam projects) is the primary HTTP client library for making outbound network requests in Gleam when running on the Erlang/BEAM virtual machine.
gleam_httpc is essentially a Gleam wrapper or "binding" around the built-in httpc library that comes with Erlang/OTP. This means it leverages the reliability and concurrency of the underlying BEAM runtime's networking capabilities.

In the client implementation , we have called the respective implemented API endpoints to 
1. Register users
2. Create subreddits
3. Join or Leave Subredddits (handle subreddit membership)
4. Create posts on the subreddit
5. Commente on Posts 
6. Commente on Comments to show hierarchial commenting support.
7. Vote on either posts or comments
8. Retrieve User Profile to view their karma
9. Retrieve user feed
10. View their inbox of messages


The Postman WebSocket client is used to validate the real-time, stateful behavior of our chat service.

1. Connection Integrity
Establishment: Postman confirms that it can successfully establish and maintain a persistent, full-duplex WebSocket connection to our Mist server.

2. Message Format and Delivery
Data Format: We send and receive messages through the Postman interface, confirming that the data transferred (the frames) adheres to the expected JSON structure you've defined for chat messages.

Two-Way Flow: Using two separate Postman connections, we  validate end-to-end message delivery and latency. This confirms our server logic can route a message received from Connection A out to Connection B in real time.

--- 

The project thus successfully developed a full-stack backend service for a Reddit application, built primarily using the Gleam language on the BEAM virtual machine.