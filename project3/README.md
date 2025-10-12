
### Assumptions and Implementation Details:
1. Central Coordination
- There is a central coordinator that tracks and executes the lookup requests by each node in the network. The coordinator ensures the termination of the program when each node has sent `requests` lookups.
2. Ring Size
- The finger table size (no of entries in finger table) is calculated as log₂(nodes) + 1.
3. SHA-1 Based Node and Key IDs
- Each node and lookup key is assigned a 160-bit identifier generated using SHA-1 hashing of the node’s IP (or simulated identifier).
- SHA-1 ensures a uniform distribution of IDs across the identifier space, minimizing clustering and improving lookup efficiency.
- The hash-based IDs are used consistently for computing finger table entries, successors, and predecessor relationships.
4. Nodes Joining
- Nodes join sequentially with fixed `joining_gap_milliseconds` i.e. `5000` milliseconds. This avoids multiple nodes joining at the same instant, reducing lookup collisions and easing stabilization.
5. Join Consistency
- Each new node finds its successor via the first node in the network (the initial nodes) and updates predecessors through Notify. This guarantees the ring structure remains consistent immediately during network growth and does not wait for a stabilize cycle.
6. Initial Stabilization:
- Each node runs its first stabilization after a short delay of `40000` milliseconds. This helps spread out stabilize calls and avoids synchronized behavior across nodes.
7. Request Scheduling:
- Lookup requests are spaced out using `requests_gap_milliseconds` i.e. `1000` milliseconds. This prevents the coordinator from overwhelming the network with simultaneous lookups. Each nodes starts sending requests to the coordinator with `requests_gap_milliseconds` immediately after joining the network. The initial node that creates the network starts sending requests after `joining_gap_milliseconds` to wait for more nodes to join the network.
8. Periodic Stabilization:
- After joining, nodes stabilize periodically every `long_stabilization_milliseconds` i.e. `60000` milliseconds. This ensures successor/predecessor pointers remain accurate as the network evolves.
9. Call Timeout:
- All blocking calls use a fixed `call_milliseconds` timeout. This allows the system to detect slow or unresponsive nodes instead of hanging indefinitely.
10. Finger Table Updates
- Finger Table updates are immediately called after the stabilization round of the node. This ensures finger table entries are updated only when the successor nodes of each node are correct.
11. Failure-Free Assumption
- Nodes do not fail or leave the network once joined. This simplifies stabilization and lookup behavior in the simulation.
12. Convergence:
- The network is considered stable once all nodes have completed their join and stabilization cycles, and all scheduled requests have been processed.
13. Performance Measurement:
- The central coordinator collects hop counts from completed lookups and calculates the average hop count to measure lookup efficiency.