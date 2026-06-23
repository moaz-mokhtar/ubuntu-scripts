#!/usr/bin/env bash

set -e

show_help() {
  cat <<EOF
Usage:
  ytbest <URL> [QUALITY]

Quality (height):
  144 240 360 480 720 1080 1440 2160

Examples:
  ytbest "https://youtu.be/VIDEO_ID"
  ytbest "https://youtu.be/VIDEO_ID" 1080
  ytbest "https://youtu.be/VIDEO_ID" 480

Notes:
  - Default quality: 720p
  - Downloads the best video up to the selected quality
  - Falls back to a lower quality if unavailable
EOF
}

if [ $# -lt 1 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  show_help
  exit 0
fi

URL="$1"
QUALITY="${2:-720}"

yt-dlp \
  -f "bestvideo[height<=${QUALITY}]+bestaudio/best[height<=${QUALITY}]" \
  --merge-output-format mp4 \
  --embed-thumbnail \
  --embed-metadata \
  --continue \
  --no-overwrites \
  -o "$HOME/Videos/%(uploader)s/%(title)s [%(height)sp].%(ext)s" \
  "$URL"
