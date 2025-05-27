#!/bin/bash

# Script to convert images to WebP format
# Usage: ./webp.sh <input_image> [quality]
# Default quality is set to 80%

# Check if cwebp is installed
if ! command -v cwebp &> /dev/null; then
    echo "Error: cwebp is not installed."
    echo "Install it using:"
    echo "  - macOS: brew install webp"
    echo "  - Ubuntu/Debian: sudo apt-get install webp"
    echo "  - CentOS/RHEL: sudo yum install libwebp-tools"
    exit 1
fi

# Check if input file is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <input_image> [quality]"
    echo "Example: $0 image.jpg 80"
    exit 1
fi

INPUT_FILE="$1"
QUALITY=${2:-80}  # Default quality is 80 if not specified

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file '$INPUT_FILE' not found."
    exit 1
fi

# Get file extension and name
FILENAME=$(basename -- "$INPUT_FILE")
EXTENSION="${FILENAME##*.}"
FILENAME="${FILENAME%.*}"
OUTPUT_FILE="${FILENAME}.webp"

# Convert image to WebP
echo "Converting $INPUT_FILE to $OUTPUT_FILE with quality $QUALITY..."
cwebp -q "$QUALITY" "$INPUT_FILE" -o "$OUTPUT_FILE"

# Check if conversion was successful
if [ $? -eq 0 ]; then
    echo "Conversion successful: $OUTPUT_FILE"
    
    # Show file size comparison
    ORIGINAL_SIZE=$(du -h "$INPUT_FILE" | cut -f1)
    NEW_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
    echo "Original size: $ORIGINAL_SIZE"
    echo "WebP size: $NEW_SIZE"
else
    echo "Conversion failed."
fi
