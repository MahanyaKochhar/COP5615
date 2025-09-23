# COP5615 Distributed Operating Systems Principles
## Project 2 - Gossip Protocol
### Project group: 24
### Team members: Mahanya Kochhar, Akshay Dhawale

This project is designed to model and evaluate the behavior of the Gossip and Push-Sum algorithms over various network topologies. It aims to explore the convergence time for these algorithms over full network, 3D grid, line and imperfect 3D grid network topologies across actor-based configurations.

The simulator allows users to define network sizes, choose different topologies and algorithms, and observe how information propagates across the system.

### What is working:

- Program successfully constructs network topologies with correctly initialized neighbors for each actor.
- Simulator executes as expected for both Gossip and Push-Sum protocols.
- Supports testing with varying network sizes and topologies, with precise time tracking.
- Both algorithms reliably converge based on predefined convergence criteria.

### Largest network sizes for each topology and algorithm:

- Push-sum algorithm:
    - Full Network: 1200
    - 3D Grid: 1400
    - Line: 1000
    - Imperfect 3D Grid: 1300

- Gossip algorithm:
    - Full Network: 1300
    - 3D Grid: 1500
    - Line: 1600
    - Imperfect 3D Grid: 1800

### Development 

  Either
```
   gleam run N T A
```
  where N = No of Nodes, T = Topology,A = Algorithm are command line inputs as in problem statement