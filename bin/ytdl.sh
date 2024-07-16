#!/bin/bash

# Check if a URL was provided
if [ -z "$1" ]; then
    echo "Usage: $0 [url]"
    echo "Example: $0 https://www.youtube.com/watch?v=dQw4w9WgXcQ"
    exit 1
fi

# Run the yt-dlp command with the provided URL
yt-dlp --extract-audio --audio-format mp3 --audio-quality 192K "$1"
