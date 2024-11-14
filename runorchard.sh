#!/bin/bash

# Define an array with the custom step values
#steps=(1 2 3 4 8 12 15 16)
first=26
steps=(${first} 27 28 29 33 37 40 41)

# Loop through each value in the array
for step in "${steps[@]}"; do
    echo "Processing cores: ${first}..$step"
	
    sudo  ./orchardj.sh ${first} $step
done

echo "completed!"

