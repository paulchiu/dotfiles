#!/bin/bash

# Function to print usage instructions
usage() {
    echo "Usage: $0 <input_dir> <output_dir>"
    exit 1
}

# Check if the correct number of arguments is provided
if [ "$#" -ne 2 ]; then
    usage
fi

# Assign arguments to variables
input_dir="$1"
output_dir="$2"

# Check if input directory exists
if [ ! -d "$input_dir" ]; then
    echo "Error: Input directory '$input_dir' does not exist."
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$output_dir"

# Loop through all HEIC files in the input directory
for heic_file in "$input_dir"/*.HEIC; do
    # Check if there are no HEIC files
    if [ ! -e "$heic_file" ]; then
        echo "No HEIC files found in '$input_dir'."
        exit 1
    fi

    # Get the base name of the file (without extension)
    base_name=$(basename "$heic_file" .HEIC)

    # Define the output JPEG file path
    jpg_file="$output_dir/$base_name.jpg"

    # Convert HEIC to JPEG and resize to 720p
    sips -s format jpeg "$heic_file" --out "$jpg_file"
    sips -Z 720 "$jpg_file"

    echo "Converted and resized: $heic_file -> $jpg_file"
done

echo "All files have been converted and resized."
