#!/bin/bash

if [ -z "$1" ]
then
  echo "No video file specified."
  exit 1
fi

input=$1

if [ -z "$2" ]
then 
  output="${input%.*}-720p.mp4"
else
  output="$2"
fi

ffmpeg -i "$input" -vf "scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2" -c:v libx264 -preset slow -crf 22 -profile:v main -level 3.1 -maxrate 10000k -bufsize 10000k -r 30 -c:a aac -b:a 128k -movflags +faststart "$output"