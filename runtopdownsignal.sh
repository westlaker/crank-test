#!/bin/bash
#pushd telemetry-solution/tools/topdown_tool

steps=(1 2 4 8 16)
first=1

	
# Define a function to handle the signal
handle_signal() {
    local val1="$1" 
    local val2="$2" 
    echo "<<< Signal received! Starting topdown on cores: $val1 .. $val2"
    sleep 5  # Simulate Program 2 running
    ./telemetry-solution/tools/topdown_tool/topdown-tool -C $val1-$val2 sleep 10 > topdown_warmup120s_$val1-$val2-1.txt
    sleep 6
    sudo perf stat -e r148,r149,r150,r36,r37 -p ${pid} sleep 8 > perfstat_warmup120s_$val1-$val2.txt 2>&1
    sudo perf stat -e r002,r005,r02D,r36,r37 -p ${pid} sleep 8 >> perfstat_warmup120s_$val1-$val2.txt 2>&1
    echo ">>> topdown completed with parameter: $val1 and $val2"
    signal_received=1  # Set the flag to exit the loop
}

# Loop through each value in the array
for step in "${steps[@]}"; do
    echo "Processing topdown on cores: ${first}..$step"

    # Reset the flag for each step
    signal_received=0
    # Use the trap to handle signals
    trap 'handle_signal "$first" "$step"' SIGUSR1
    echo "Waiting for signal to process topdown on cores: $first .. $step"
    # Wait for the signal
    while [[ $signal_received -eq 0 ]]; do
        sleep 1  # Idle until a signal is received
    done
done
