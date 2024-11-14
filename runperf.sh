#!/bin/bash

pid=$(ps -ef | grep -i "cms" | grep -v "grep" | awk '{print $2}')
echo $pid
sudo perf stat -e r148,r149,r150 -p ${pid} sleep 10
sudo perf stat -e r002,r005,r02D -p ${pid} sleep 10
