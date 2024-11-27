#!/bin/bash

outputfile="rps_120s_20s-egorknobs.txt"
echo "Cores TotalRequests seconds Requests/sec" > ${outputfile}

for core in 1 2 4 8 16
do
    # Specify the file name
    filename=results9.0_1-${core}_120s_20s-egorknobs.txt
    # Extract all "requests" values and store them in an array
    requests=($(grep -oP '\d+(?= requests in)' "$filename"))

    # Extract all "Requests/sec" values and store them in an array
    requests_per_sec=($(grep -oP 'Requests/sec:\s*\K\d+(\.\d+)?' "$filename"))
    # Loop through the arrays and display the results
    for i in "${!requests[@]}"; do
	echo "Instance $((i + 1)):"
	echo "  TotalRequests: ${requests[i]}"
	echo "  Requests/sec: ${requests_per_sec[i]}"
	echo ""
	if ((i > 0 )); then
	    echo "$core ${requests[i]} 20 ${requests_per_sec[i]}" >> ${outputfile}
	fi
    done
done

