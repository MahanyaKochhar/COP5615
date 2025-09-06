
# Project 1 : Sums of Consecutive Squares

1. **Work Unit Size**

    **sqrt(N)**

    Each worker (child actor) receiving sqrt(N) numbers to verify the sums of squares of k consecutive numbers beginning at each index leads to the best performance for our implementation. 


2. **Why the following size?**

    This size was selected as too small a unit size would mean too much message passing overhead. Too large a unit size would mean poor load balancing across cores. The chosen unit size provided the best balance between computation and communication overhead. We also brute forced and tested for smaller and larger work units and accordingly the no of actors created.

3. **The result of running this program for lukas 1000000 4**


    No sums of squares of 4 consecutive numbers starting at 1 or higher and upto 1000000 is a perfect square and hence there are no solutions. The output is empty.
```
% time gleam run 1000000 4
   Compiled in 0.03s
    Running project1.main
```

4. **The REAL TIME as well as the ratio of CPU TIME to REAL TIME for the above, i.e. for lukas 1000000 4.**

    **REAL TIME = 0.234s**

    **CPU TIME/REAL_TIME = 0.57**
   
    To evaluate performance, we need REAL time (wall clock time) and CPU time (work done across all cores). We achieved this by using the "time" package while running the gleam project.

Example 1:

```
% time gleam run 1000000 4
   Compiled in 0.03s
    Running project1.main
gleam run 1000000 4  0.38s user 0.19s system 245% cpu 0.234 total
```

    - Total CPU Time = User CPU Time + System CPU Time = (0.38 + 0.19)s = 0.57s
    - Real Time = 0.234s
    - CPU Time / Real Time = 2.436

Example 2:

```
% time gleam run 100000000 20
   Compiled in 0.02s
    Running project1.main
62780852
88700958
gleam run 100000000 20  51.53s user 5.15s system 365% cpu 15.490 total
```
    - Total CPU Time = User CPU Time + System CPU Time = (51.53 + 5.15)s = 56.68s
    - Real Time = 15.49s
    - CPU Time / Real Time = 3.659
    
5. **Largest problem solved -**
```
% time gleam run 100000000 20
   Compiled in 0.02s
    Running project1.main
62780852
88700958
```

### Development 

  Either
  1. gleam run N K 

        or

  2. gleam run N K C

  where N, K are command line inputs as in problem statement and C = no of units each worker gets. To pass C as command line argument is optional.
