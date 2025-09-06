# README: Project Group 24
## Sum of Consecutive Squares

==============================================================

* Work Unit Size

Work unit size chosen: 

This size was selected as too small a unit size would mean too much message passing overhead. Too large a unit size would mean poor load balancing across cores. The chosen unit size provided the best balance between computation and communication overhead.

==============================================================

* The result of running this program for lukas 1000000 4 is Nil.
```
PS D:\UF\Sem1\DOSP\Gleam\Project_1\project1> gleam run 1000000 4
   Compiled in 0.11s
    Running project1.main
```
==============================================================

* Measuring REAL time and the ratio of CPU vs REAL Time

To evaluate performance, we need REAL time (wall clock time) and CPU time (work done across all cores).
We achieved this by using the "time" package while running the gleam project. This was used while running two testcases, their respective CPU utilization is captured using "Percent of CPU this job got" paramter.
```
$ /usr/bin/time -v gleam run 100000000 20
   Compiled in 18.71s
    Running project1.main
62780852
88700958
        Command being timed: "gleam run 100000000 20"
        User time (seconds): 320.08
        System time (seconds): 74.21
        Percent of CPU this job got: 307%
        Elapsed (wall clock) time (h:mm:ss or m:ss): 2:08.02   
```

```
$ /usr/bin/time -v gleam run 4000000 24
   Compiled in 20.39s
    Running project1.main
1
9
20
25
44
76
121
197
304
353
540
856
1301
2053
3112
3597
8576
20425
5448
35709
12981
54032
84996
30908
128601
202289
306060
353585
534964
841476
1273121
2002557
3029784
3500233
        Command being timed: "gleam run 4000000 24"
        User time (seconds): 9.51
        System time (seconds): 2.40
        Percent of CPU this job got: 40%
        Elapsed (wall clock) time (h:mm:ss or m:ss): 0:29.22
```
==============================================================

* The largest problem we successfully managed to solve was
```
$  gleam run 100000000 20
   Compiled in 0.09s
    Running project1.main
62780852
88700958
```
==============================================================


