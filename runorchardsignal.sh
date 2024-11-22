#!/bin/bash

# Define an array with the custom step values
#first=26
#steps=(${first} 27 28 29 33 37 40 41)
steps=(1 2 4 8 16)
first=1

# Loop through each value in the array
for step in "${steps[@]}"; do
    echo "Processing cores: ${first}..$step"
	
    sudo  ./orchardsignal.sh ${#first} $step
done

echo "completed!"

