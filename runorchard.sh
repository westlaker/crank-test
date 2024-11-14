#!/bin/bash

# Define an array with the custom step values
steps=(1 2 3 4 8 12 15 16)

# Loop through each value in the array
for step in "${steps[@]}"; do
    echo "Processing cores: 1..$step"
	
    sudo sh orchardj.sh 1 $step
done

echo "completed!"

