#!/bin/bash

# Output file
output="combined_files.csv"

# Process the first file separately to handle the header
first_file=true
for file in *.csv; do
    # Remove the.csv extension from the file name
    filename=$(basename -- "$file")
    filename="${filename%.*}"

    # Check if it's the first file
    if $first_file; then
        # Copy the entire file including the header
        awk -v fname="$filename" '{print fname "," $0}' "$file" > $output
        first_file=false
    else
        # Skip the header and prepend the file name to each line
        tail -n +2 "$file" | awk -v fname="$filename" '{print fname "," $0}' >> $output
    fi
done
