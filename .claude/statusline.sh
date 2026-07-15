#!/bin/bash
# Claude Code status line, single row: model, dir, git branch, context usage bar.
# Receives session JSON on stdin. See https://code.claude.com/docs/en/statusline

# Nerd Font glyphs (FiraCode Nerd Font), built from UTF-8 bytes so the private-use
# codepoints survive editors and diffs that mangle raw PUA characters.
#   nf-fa-microchip   U+F2DB
#   nf-fa-folder      U+F07B
#   nf-dev-git_branch U+E725
ICON_MODEL=$(printf '\xef\x8b\x9b')
ICON_DIR=$(printf '\xef\x81\xbb')
ICON_GIT=$(printf '\xee\x9c\xa5')

input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name // "?"')
DIR=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
SIZE=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
USED=$(echo "$input" | jq -r '
  (.context_window.total_input_tokens // 0) +
  (.context_window.total_output_tokens // 0)')

# Human-readable token counts, e.g. 90k/200k or 427k/1M
fmt_k() {
  awk -v n="$1" 'BEGIN {
    if (n >= 1000000) printf "%.1fM", n/1000000
    else if (n >= 1000) printf "%.0fk", n/1000
    else printf "%d", n
  }' | sd '\.0M' 'M'
}
USED_H=$(fmt_k "$USED")
SIZE_H=$(fmt_k "$SIZE")

# Eight-segment bar, colour-coded by pressure on the window
SEGMENTS=8
FILLED=$((PCT * SEGMENTS / 100))
[ "$FILLED" -gt "$SEGMENTS" ] && FILLED=$SEGMENTS
BAR=""
for i in $(seq 1 "$SEGMENTS"); do
  if [ "$i" -le "$FILLED" ]; then BAR="${BAR}█"; else BAR="${BAR}░"; fi
done

if   [ "$PCT" -ge 80 ]; then COLOR=$'\033[31m'   # red
elif [ "$PCT" -ge 50 ]; then COLOR=$'\033[33m'   # yellow
else                         COLOR=$'\033[32m'   # green
fi
RESET=$'\033[0m'
DIM=$'\033[2m'

BRANCH=$(git -C "${DIR:-.}" rev-parse --abbrev-ref HEAD 2>/dev/null)
GIT_SEG=""
[ -n "$BRANCH" ] && GIT_SEG=" ${ICON_GIT} ${BRANCH}"

printf '%s%s %s %s %s%s%s %s%s%s %s%% %s(%s/%s)%s\n' \
  "$DIM" "$ICON_MODEL" "$MODEL" "$ICON_DIR" "${DIR##*/}" "$GIT_SEG" "$RESET" \
  "$COLOR" "$BAR" "$RESET" "$PCT" \
  "$DIM" "$USED_H" "$SIZE_H" "$RESET"
