#!/usr/bin/env bash
#
# cch.sh - Claude Code History: fuzzy-search your past Claude Code prompts
#          (the same list ctrl-r searches) and copy one to the clipboard.
#
# Usage:
#   cch.sh [-p] [-a] [query...]
#
#   -a, --all       Browse the full history with no initial filter
#   -p, --project   Only prompts entered from the current directory's project
#   -h, --help      Show this help
#   query...        Optional initial fzf search string
#
# Running with no arguments prints this help. Use -a to browse everything.
#
# Keys inside fzf:
#   enter   copy the highlighted prompt to the clipboard (pbcopy)
#   ctrl-p  toggle the full-text preview pane
#   esc     quit without copying
#
# Prompts are shown most-recent-first and de-duplicated. Multi-line prompts
# are flattened to one line in the list; the preview pane shows them in full.

set -euo pipefail

HIST="${CLAUDE_HISTORY:-$HOME/.claude/history.jsonl}"

usage() {
  # Print only the leading comment block (after the shebang, up to the first
  # non-comment line) as help text.
  awk 'NR==1 { next } /^#/ { sub(/^# ?/, ""); print; next } { exit }' "$0"
}

# No arguments at all: show help rather than launching the picker.
if [[ $# -eq 0 ]]; then
  usage
  exit 0
fi

project_only=0
query=()
for arg in "$@"; do
  case "$arg" in
    -a|--all) : ;;  # browse-all is the default; flag just opts in explicitly
    -p|--project) project_only=1 ;;
    -h|--help) usage; exit 0 ;;
    *) query+=("$arg") ;;
  esac
done

if [[ ! -f "$HIST" ]]; then
  echo "cch: history file not found: $HIST" >&2
  exit 1
fi
if ! command -v fzf >/dev/null 2>&1; then
  echo "cch: fzf is required but not on PATH" >&2
  exit 1
fi

# Optional project filter: match prompts whose recorded project == $PWD.
proj_filter='.'
if [[ "$project_only" == 1 ]]; then
  proj_filter="select(.project == \"$PWD\")"
fi

# Emit "base64(display)<TAB>coloured-label" per record, then reverse to
# most-recent-first and drop duplicate prompts (keeping the newest).
# base64 keeps every prompt on a single line and doubles as the copy payload.
build_list() {
  jq -r "
    select(.display and (.display | length > 0))
    | $proj_filter
    | ((.timestamp / 1000 | floor) | strflocaltime(\"%Y-%m-%d %H:%M\")) as \$date
    | (.project // \"\" | split(\"/\") | last) as \$proj
    | (.display | gsub(\"\\\\s+\"; \" \") | .[0:300]) as \$flat
    | (.display | @base64) as \$b64
    | \"\(\$b64)\t[2m\(\$date)[0m  [36m\(\$proj)[0m  \(\$flat)\"
  " "$HIST" | tail -r | awk -F'\t' '!seen[$1]++'
}

# Preview / copy both decode field 1 (base64) of the selected line.
decoder='printf %s {1} | base64 -d'

selection=$(
  build_list | fzf \
    --ansi \
    --delimiter="$(printf '\t')" \
    --with-nth=2.. \
    --no-sort \
    --no-hscroll \
    --height=80% \
    --layout=reverse \
    --border \
    --prompt='claude ctrl-r> ' \
    --query="${query[*]}" \
    --preview="$decoder" \
    --preview-window='down,45%,wrap,border-top' \
    --bind='ctrl-p:toggle-preview'
) || exit 0

[[ -z "$selection" ]] && exit 0

# First tab-delimited field is the base64 payload; decode straight to clipboard.
b64="${selection%%$'\t'*}"
printf %s "$b64" | base64 -d | pbcopy

echo "Copied to clipboard:"
printf %s "$b64" | base64 -d | head -3
lines=$(printf %s "$b64" | base64 -d | wc -l | tr -d ' ')
[[ "$lines" -gt 3 ]] && echo "  ... (+$((lines - 2)) more lines)"
