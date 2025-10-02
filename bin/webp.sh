#!/bin/bash

#!/bin/bash

# Script to convert images to WebP format
# Usage:
#   ./webp.sh <input_image ...> [quality]
# Examples:
#   ./webp.sh image.jpg
#   ./webp.sh image1.png image2.jpg 90
#   ./webp.sh *.png 80
# Default quality is 80
# This script preserves metadata and color profile (EXIF/XMP/ICC) in output WebP.

# Check if cwebp is installed
if ! command -v cwebp &> /dev/null; then
    echo "Error: cwebp is not installed."
    echo "Install it using:"
    echo "  - macOS: brew install webp"
    echo "  - Ubuntu/Debian: sudo apt-get install webp"
    echo "  - CentOS/RHEL: sudo yum install libwebp-tools"
    exit 1
fi

# Parse args: allow multiple input files and optional trailing quality
if [ $# -lt 1 ]; then
  echo "Usage: $0 <input_image ...> [quality]"
  echo "Examples: $0 image.jpg | $0 *.png 80"
  exit 1
fi

# Determine if last arg is a numeric quality 0-100
QUALITY=80
last_arg="${!#}"
if [[ "$last_arg" =~ ^[0-9]{1,3}$ ]] && [ "$last_arg" -ge 0 ] && [ "$last_arg" -le 100 ]; then
  QUALITY="$last_arg"
  # Remove the last argument (quality) from the list
  set -- "${@:1:$(($#-1))}"
fi

# Ensure we still have inputs
if [ $# -lt 1 ]; then
  echo "Error: No input files provided."
  echo "Usage: $0 <input_image ...> [quality]"
  exit 1
fi

overall_fail=0
for INPUT_FILE in "$@"; do
  if [ ! -f "$INPUT_FILE" ]; then
    echo "Skipping: '$INPUT_FILE' not found or not a regular file."
    overall_fail=1
    continue
  fi

  FILENAME=$(basename -- "$INPUT_FILE")
  EXTENSION="${FILENAME##*.}"
  FILENAME="${FILENAME%.*}"
  OUTPUT_FILE="${FILENAME}.webp"

  echo "Converting $INPUT_FILE -> $OUTPUT_FILE (q=$QUALITY, metadata=all)"
  if cwebp -quiet -metadata all -q "$QUALITY" "$INPUT_FILE" -o "$OUTPUT_FILE"; then
    ORIGINAL_SIZE=$(du -h "$INPUT_FILE" | cut -f1)
    NEW_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
    echo "  ✓ Success: $OUTPUT_FILE (was $ORIGINAL_SIZE, now $NEW_SIZE)"
  else
    echo "  ✗ Failed to convert: $INPUT_FILE"
    overall_fail=1
  fi
done

exit $overall_fail
