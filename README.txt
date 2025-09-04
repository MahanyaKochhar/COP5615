README

Project group 24 - Sum of squares

1. Work Unit Size

Work unit size chosen: <Mention the number of subproblems a worker gets in a single request from the boss.>

This size was selected as too small a unit size would mean too much message passing overhead. Too large a unit size would mean poor load balancing across cores. The chosen unit size provided the best balance between computation and communication overhead.

2. The result of running this program for lukas 1000000 4 is 0.

PS D:\UF\Sem1\DOSP\Gleam\Project_1\project1> gleam run 1000000 4
   Compiled in 0.11s
    Running project1.main
PS D:\UF\Sem1\DOSP\Gleam\Project_1\project1> 

3. Measuring REAL time and the ratio of CPU vs REAL Time

To evaluate performance, we need REAL time (wall clock time) and CPU time (work done across all cores).
We achieved this by using the "time" package while running the gleam project. This was used while running two testcases, their respective ratio is recorded using the average cores used formula:
Average cores used = Total CPU time / Real time

$ /usr/bin/time -v gleam run 3 2
   Compiled in 7.15s
    Running project1.main
3
        Command being timed: "gleam run 3 2"
        User time (seconds): 2.64
        System time (seconds): 1.32
        Elapsed (wall clock) time (h:mm:ss or m:ss): 0:16.01

Real time = 3.96

Average cores used            = (2.64 + 1.32) / 16.01
(CPU time to REAL time ratio) = 0.2473
                              = 24.73%

$ /usr/bin/time -v gleam run 40 24
   Compiled in 18.82s
    Running project1.main
1
9
25
20
        Command being timed: "gleam run 40 24"
        User time (seconds): 2.37
        System time (seconds): 1.63
        Elapsed (wall clock) time (h:mm:ss or m:ss): 0:26.68

Real time = 4

Average cores used            = (2.37 + 1.63) / 26.68
(CPU time to REAL time ratio) = 0.1499
                              ~ 15%

4. The largest problem we successfully managed to solve was lukas 1000000 4?

==============================================================