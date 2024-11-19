#!/bin/bash

echo "Press any key to capture perf stat for 1 core ..."
read -n 1 key
pid=$(ps -ef | grep -i "cms" | grep -v "grep" | awk '{print $2}')
echo $pid
sudo perf stat -e r148,r149,r150,r36,r37 -p ${pid} sleep 10 >perfstat_1core.txt 2>&1
sudo perf stat -e r002,r005,r02D,r36,r37 -p ${pid} sleep 10 >>perfstat_1core.txt 2>&1

echo "Press any key to capture perf stat for 2 core ..."
read -n 1 key
pid=$(ps -ef | grep -i "cms" | grep -v "grep" | awk '{print $2}')
echo $pid
sudo perf stat -e r148,r149,r150,r36,r37 -p ${pid} sleep 10 >perfstat_2core.txt 2>&1
sudo perf stat -e r002,r005,r02D,r36,r37 -p ${pid} sleep 10 >>perfstat_2core-txt 2>&1

echo "Press any key to capture perf stat for 4 core ..."
read -n 1 key
pid=$(ps -ef | grep -i "cms" | grep -v "grep" | awk '{print $2}')
echo $pid
sudo perf stat -e r148,r149,r150,r36,r37 -p ${pid} sleep 10 >perfstat_4core.txt 2>&1
sudo perf stat -e r002,r005,r02D,r36,r37 -p ${pid} sleep 10 >>perfstat_4core.txt 2>&1

echo "Press any key to capture perf stat for 8 core #1..."
read -n 1 key
pid=$(ps -ef | grep -i "cms" | grep -v "grep" | awk '{print $2}')
echo $pid
sudo perf stat -e r148,r149,r150,r36,r37 -p ${pid} sleep 10 >perfstat_8core.txt 2>&1
sudo perf stat -e r002,r005,r02D,r36,r37 -p ${pid} sleep 10 >>perfstat_8core.txt 2>&1

echo "Press any key to capture perf stat for 16 core..."
read -n 1 key
pid=$(ps -ef | grep -i "cms" | grep -v "grep" | awk '{print $2}')
echo $pid
sudo perf stat -e r148,r149,r150,r36,r37 -p ${pid} sleep 10 >perfstat_16core.txt 2>&1
sudo perf stat -e r002,r005,r02D,r36,r37 -p ${pid} sleep 10 >>perfstat_16core.txt 2>&1
