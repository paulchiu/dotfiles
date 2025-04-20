#!/bin/bash

# Check if both album and genre arguments are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <album_name> <genre>"
    echo "Example: $0 \"Greatest Hits\" \"Rock\""
    exit 1
fi

# Store the album name and genre from the command line arguments
album="$1"
genre="$2"

# Loop through all MP3 files in the current directory
for f in *.mp3; do
    # Extract artist and song title from the filename
    # Assuming the format is [artist] - [song title].mp3
    artist=$(echo "$f" | sed -E -n 's/^(.*) - .*/\1/p')
    title=$(echo "$f" | sed -E -n 's/^.*\ - (.*).mp3/\1/p')

    # Use eyeD3 to set the artist, title, album, and genre metadata
    eyeD3 --artist="$artist" --title="$title" --album="$album" --genre="$genre" "$f"

    echo "Updated: $f (Artist: $artist, Title: $title, Album: $album, Genre: $genre)"
done

echo "✨ All MP3 files have been updated"
