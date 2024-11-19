This is testing OrchardCMS on .Net on Linux

Non-Crank Single Machine OrchardCMS

In case if you want a simpler way to test OrchardCMS (on a single machine without extra machines for load/controller) there is an automated script to do so. We still recommend using crank, but this script might be useful for e.g. low-level profiling or quick tests.

OrchardCMS is a web application framework (Content Management System). The benchmark setups a basic page (About) and a load generator (either wrk or bombardier) just sends GET requests for that page. The number of requests per second (RPS) is then reported. We don't measure latency or anything else for this benchmark.


