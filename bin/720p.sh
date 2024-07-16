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

ffmpeg -i "$input" -c:v libx264 -preset slow -crf 22 -c:a aac -b:a 128k -ar 44100 -filter:v "scale='min(1280,iw)':min'(720,ih)':force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2" "$output"