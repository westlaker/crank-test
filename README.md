This is testing OrchardCMS on .Net on Linux

Non-Crank Single Machine OrchardCMS

In case if you want a simpler way to test OrchardCMS (on a single machine without extra machines for load/controller) there is an automated script to do so. We still recommend using crank, but this script might be useful for e.g. low-level profiling or quick tests.

OrchardCMS is a web application framework (Content Management System). The benchmark setups a basic page (About) and a load generator (either wrk or bombardier) just sends GET requests for that page. The number of requests per second (RPS) is then reported. We don't measure latency or anything else for this benchmark.

To Run OrchardCMS Benchmark while collecting Performance results and Topdown results

On one terminal do:
./runtopdownsignal.sh
It collects topdown data based on the cores 1, 2, 4, 8, 16 the OrchardCMS app runs on and collect the topdown data on these cores with the files:
topdown_warmup120s_1-1-1.txt
topdown_warmup120s_1-2-1.txt
topdown_warmup120s_1-4-1.txt
topdown_warmup120s_1-8-1.txt
topdown_warmup120s_1-16-1.txt

On other terminal do:
./runorchardsignal.sh  
It will start OrchardCMS app on cores 1, 2, 4, 8, 16, and run wrk traffic towards OrchardCMS app and record the results for cores 1, 2, 4, 8, 16 with the files:
results9.0_1-1_120s_20s.txt
results9.0_1-2.txt
results9.0_1-4.txt
results9.0_1-8.txt
results9.0_1-16_120s_20s.txt

Couple things to start with:

1) We need to enable THP on the system:

$ echo always | sudo tee /sys/kernel/mm/transparent_hugepage/enabled
$ cat /sys/kernel/mm/transparent_hugepage/enabled
[always] madvise never

2) We need to configure performance to the scaling_governor

$ echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

3) We need to set CPU HW Freq to as closer as possible to compare the results for different CPUs

$ sudo cpufreq-set -f 2.8GHz
$ sudo cat /sys/devices/system/cpu/cpu*/cpufreq/cpuinfo_cur_freq
2400000
$ ./mhz-aarch64
2399 MHz, 0.4168 nanosec clock

4) the OrchardCMS app has better results to have higher WARMUP time set to be 120s

In orchardsignal.sh,  set:
: ${WARM:="120s"}          # warm up run time in seconds
: ${RUN:="20s"}            # run test time

5) Also enable these to have symbols enabled
: ${USE_PERF:="1"}
: ${ALL_SYMBOLS:="1"}

You need to rebuild orchard-bench9.0  by removing the existing one


