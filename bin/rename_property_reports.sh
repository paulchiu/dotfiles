#!/bin/bash

# Loop through all .html files in the current folder
for f in *.html; do
  # Check if the filename contains the RP Data pipe character
  if [[ "$f" == *" ｜ "* ]]; then
    # Strip everything from the first " ｜" to the end and add .html back
    new_name="${f%% ｜*}.html"

    echo "Renaming: $f"
    echo "      To: $new_name"

    mv "$f" "$new_name"
  fi
done
