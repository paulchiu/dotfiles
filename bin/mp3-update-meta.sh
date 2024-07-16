#!/bin/bash

# Loop through all MP3 files in the current directory
for f in *.mp3; do
    # Extract artist and song title from the filename
    # Assuming the format is [artist] - [song title].mp3
    artist=$(echo "$f" | sed -E -n 's/^(.*) - .*/\1/p')
    title=$(echo "$f" | sed -E -n 's/^.*\ - (.*).mp3/\1/p')

    # Use eyeD3 to set the artist and title metadata
    eyeD3 --artist="$artist" --title="$title" "$f"
done
