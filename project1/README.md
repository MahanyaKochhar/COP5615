
# Project 1 : Sums of Consecutive Squares

1. **Work Unit Size**

    **sqrt(N)**

    Each worker (child actor) receiving sqrt(N) numbers to verify the sums of squares of k consecutive numbers beginning at each index leads to the best performance for our implementation. 


2. **Why the following size?**

    This size was selected as too small a unit size would mean too much message passing overhead. Too large a unit size would mean poor load balancing across cores. The chosen unit size provided the best balance between computation and communication overhead. We also brute forced and tested for smaller and larger work units and accordingly the no of actors created.

3. **The result of running this program for lukas 1000000 4**


    No sums of squares of 4 consecutive numbers starting at 1 or higher and upto 1000000 is a perfect square and hence there are no solutions. The output is empty.

    - gleam run 1000000 4
    - Compiled in 0.02s
    - Running project1.main

4. **The REAL TIME as well as the ratio of CPU TIME to REAL TIME for the above, i.e. for lukas 1000000 4.**

    **REAL TIME = 0.226s**

    **CPU TIME/REAL_TIME = 2.478**

    To evaluate performance, we need REAL time (wall clock time) and CPU time (work done across all cores). We achieved this by using the "time" package while running the gleam project.

    - time gleam run 1000000 4
    - Compiled in 0.02s
    - Running project1.main
    - gleam run 1000000 4  0.38s user 0.18s system 246% cpu 0.226 total

    - Total CPU Time = User CPU Time + System CPU Time = (0.38 + 0.18)s = 0.56s
    - Real Time = 0.226s
    - CPU Time / Real Time = 2.478

5. **Largest problem solved?**

      **gleam run 1e8 4**



### Development 

  Either
  1. gleam run N K 

        or

  2. gleam run N K C

  where N, K are command line inputs as in problem statement and C = no of units each worker gets. To pass C as command line argument is optional.




