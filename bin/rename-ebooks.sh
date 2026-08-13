#!/bin/bash
#
# rename-ebooks.sh — normalise "Anna's Archive" ebook filenames.
#
# Anna's Archive names look like:
#   <Title> -- <Authors> -- <Edition/Place/Year> -- <Publisher> -- isbn13 <ISBN> -- <hash> -- Anna's Archive.<ext>
#
# This rewrites them to the library convention:
#   <Title[ - Subtitle]>. <Surname, F.[, & Surname2, G.]> <Year>.<ext>
#
# Usage:
#   rename-ebooks.sh [dir]           # dry run (default): show proposed renames
#   rename-ebooks.sh --apply [dir]   # actually rename
#
# Notes:
#  - Best-effort parse. Corporate/editor authors and truncated subtitles are
#    left as-is; always review the dry run before --apply.
#  - Year is taken from the first 19xx/20xx found in the metadata; omitted if none.

set -euo pipefail

APPLY=0
DIR="."
for arg in "$@"; do
  case "$arg" in
    --apply) APPLY=1 ;;
    -h|--help) grep '^#' "$0" | cut -c3-; exit 0 ;;
    *) DIR="$arg" ;;
  esac
done

# Convert one authors field ("Joyce Russell, Ben Russell") to "Russell, J., & Russell, B."
convert_authors() {
  local raw="$1"
  local -a parts converted
  IFS=',' read -ra parts <<< "$raw"
  local p trimmed
  for p in "${parts[@]}"; do
    trimmed="$(echo "$p" | sed 's/^ *//; s/ *$//')"
    [[ -z "$trimmed" ]] && continue
    # Keep corporate / editorial names verbatim.
    if [[ "$trimmed" == *"&"* ]] || \
       [[ "$trimmed" =~ (Press|Editors|Institute|Publish|Company|Inc|Ltd|LLC|Assoc|Society|University|Committee|Department|Books|Media|[Ee]d\.?|of[[:space:]]) ]]; then
      converted+=("$trimmed")
      continue
    fi
    local -a words
    IFS=' ' read -ra words <<< "$trimmed"
    local n=${#words[@]}
    if (( n >= 2 )); then
      local last="${words[n-1]}"
      local initial="${words[0]:0:1}"
      converted+=("$last, ${initial}.")
    else
      converted+=("$trimmed")
    fi
  done

  local cn=${#converted[@]}
  if (( cn == 0 )); then
    echo ""
  elif (( cn == 1 )); then
    echo "${converted[0]}"
  else
    local head="" i
    for (( i=0; i<cn-1; i++ )); do
      head+="${converted[i]}"
      (( i < cn-2 )) && head+=", "
    done
    echo "${head}, & ${converted[cn-1]}"
  fi
}

shopt -s nullglob
found=0

for f in "$DIR"/*; do
  base="$(basename "$f")"
  # Only touch Anna's Archive files.
  [[ "$base" == *" -- "* && "$base" == *"Anna"*"Archive"* ]] || continue
  found=1

  ext="${base##*.}"
  name="${base%.*}"

  # Split on " -- " into fields.
  local_rest="$name"
  fields=()
  while [[ "$local_rest" == *" -- "* ]]; do
    fields+=("${local_rest%% -- *}")
    local_rest="${local_rest#* -- }"
  done
  fields+=("$local_rest")

  title="${fields[0]:-}"
  authors_raw="${fields[1]:-}"

  # Normalise subtitle separators: " _ " and " : " -> " - ".
  title="$(echo "$title" | sed 's/ _ / - /g; s/ : / - /g; s/  */ /g; s/ *$//')"

  # Find a 4-digit year anywhere in the metadata.
  year=""
  for fld in "${fields[@]}"; do
    if [[ "$fld" =~ (19|20)[0-9][0-9] ]]; then
      year="${BASH_REMATCH[0]}"
      break
    fi
  done

  authors="$(convert_authors "$authors_raw")"

  new="$title"
  [[ -n "$authors" ]] && new="$new. $authors"
  [[ -n "$year" ]] && new="$new $year"
  new="$new.$ext"

  if [[ "$new" == "$base" ]]; then
    continue
  fi

  echo "FROM: $base"
  echo "  TO: $new"
  echo

  if (( APPLY )); then
    if [[ -e "$DIR/$new" ]]; then
      echo "  ! target exists, skipping" >&2
    else
      mv -n "$DIR/$base" "$DIR/$new"
    fi
  fi
done

if (( ! found )); then
  echo "No Anna's Archive ebooks found in: $DIR"
elif (( ! APPLY )); then
  echo "(dry run — re-run with --apply to rename)"
fi
