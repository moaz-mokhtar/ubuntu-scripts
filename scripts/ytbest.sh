#!/usr/bin/env bash

set -e

show_help() {
  cat <<EOF
Usage:
  ytbest <URL> [QUALITY] [OPTIONS]

Arguments:
  URL       Video or playlist URL
  QUALITY   Video height (default: 720)
            Accepted: 144 240 360 480 720 1080 1440 2160

Options:
  -p, --playlist    Download as a playlist
  -h, --help        Show this help

Examples:
  ytbest "https://youtu.be/VIDEO_ID"
  ytbest "https://youtu.be/VIDEO_ID" 1080
  ytbest "https://youtube.com/playlist?list=PL..." -p
  ytbest "https://youtube.com/playlist?list=PL..." 480 -p

Notes:
  - Default quality: 720p
  - Downloads the best video up to the selected quality
  - Falls back to a lower quality if unavailable
  - Playlist videos are saved under a subfolder named after the playlist
  - Playlist filenames are prefixed with their index (e.g. 01 - Title)
EOF
}

# ── Defaults ─────────────────────────────────────────────────────────────────
QUALITY=720
IS_PLAYLIST=false
URL=""

# ── Argument parsing ──────────────────────────────────────────────────────────
for arg in "$@"; do
  case "$arg" in
  -h | --help)
    show_help
    exit 0
    ;;
  -p | --playlist)
    IS_PLAYLIST=true
    ;;
  -*)
    echo "Error: Unknown option: $arg" >&2
    echo "Run 'ytbest --help' for usage." >&2
    exit 1
    ;;
  *)
    if [[ -z "$URL" ]]; then
      URL="$arg"
    elif [[ "$arg" =~ ^[0-9]+$ ]]; then
      QUALITY="$arg"
    else
      echo "Error: Unexpected argument: $arg" >&2
      echo "Run 'ytbest --help' for usage." >&2
      exit 1
    fi
    ;;
  esac
done

if [[ -z "$URL" ]]; then
  show_help
  exit 1
fi

# ── Playlist detection ────────────────────────────────────────────────────────
detect_url_type() {
  local url="$1"
  yt-dlp --flat-playlist -J --quiet --no-warnings "$url" 2>/dev/null |
    python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('_type', 'video'))
except Exception:
    print('video')
" 2>/dev/null || echo "video"
}

echo "Inspecting URL..." >&2
URL_TYPE=$(detect_url_type "$URL")

if [[ "$IS_PLAYLIST" = false && "$URL_TYPE" = "playlist" ]]; then
  echo "Error: The URL points to a playlist." >&2
  echo "       Add -p or --playlist to download it, or supply a direct video URL." >&2
  exit 1
fi

# ── Build yt-dlp command ──────────────────────────────────────────────────────
YTDLP_ARGS=(
  -f "bestvideo[height<=${QUALITY}]+bestaudio/best[height<=${QUALITY}]"
  --merge-output-format mp4
  --embed-thumbnail
  --embed-metadata
  --continue
  --no-overwrites
)

if [[ "$IS_PLAYLIST" = true ]]; then
  YTDLP_ARGS+=(
    --yes-playlist
    -o "$HOME/Videos/yt-dlp_videos/%(uploader)s/%(playlist_title)s/%(playlist_index)02d - %(title)s [%(height)sp].%(ext)s"
  )
else
  YTDLP_ARGS+=(
    --no-playlist
    -o "$HOME/Videos/yt-dlp_videos/%(uploader)s/%(title)s [%(height)sp].%(ext)s"
  )
fi

mkdir -p "$HOME/Videos/yt-dlp_videos"

yt-dlp "${YTDLP_ARGS[@]}" "$URL"
