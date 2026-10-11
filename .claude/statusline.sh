#!/bin/bash
# Claude Code status line, single row: model, dir, git branch, context usage bar.
# Receives session JSON on stdin. See https://code.claude.com/docs/en/statusline

# Nerd Font glyphs (FiraCode Nerd Font), built from UTF-8 bytes so the private-use
# codepoints survive editors and diffs that mangle raw PUA characters.
#   nf-fa-microchip   U+F2DB
#   nf-fa-folder      U+F07B
#   nf-dev-git_branch U+E725
#   nf-fa-code_fork   U+F126  (marks a linked worktree)
#   nf-fa-hourglass_half U+F252  (prompt cache warm)
#   nf-fa-snowflake   U+F2DC  (prompt cache cold)
#   nf-fa-comments    U+F086  (prompts sent)
#   nf-oct-fold       U+F48C  (compact before N more prompts)
ICON_MODEL=$(printf '\xef\x8b\x9b')
ICON_DIR=$(printf '\xef\x81\xbb')
ICON_GIT=$(printf '\xee\x9c\xa5')
ICON_WT=$(printf '\xef\x84\xa6')
ICON_CACHE=$(printf '\xef\x89\x92')
ICON_COLD=$(printf '\xef\x8b\x9c')
ICON_TURNS=$(printf '\xef\x82\x86')
ICON_FOLD=$(printf '\xef\x92\x8c')

input=$(cat)

# Claude Code exports COLUMNS before running this script. tput cannot help here:
# output is captured rather than attached to a TTY.
COLS=${COLUMNS:-120}

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

# Prompt cache countdown to prompt_cache.expires_at, yellow in the last fifth of the
# TTL. Once cold, shows the tokens the next request will re-cache.
CACHE_EXP=$(echo "$input" | jq -r '.prompt_cache.expires_at // empty' | cut -d. -f1)
CACHE_TTL=$(echo "$input" | jq -r '.prompt_cache.ttl // "5m"')
RECACHE=$(echo "$input" | jq -r '.prompt_cache.recache_tokens_if_cold // empty')
CACHE_TXT=""
CACHE_SEG=""
if [ -n "$CACHE_EXP" ]; then
  LEFT=$((CACHE_EXP - $(date +%s)))
  if [ "$CACHE_TTL" = "1h" ]; then TTL_S=3600; else TTL_S=300; fi
  if [ "$LEFT" -le 0 ]; then
    CACHE_TXT="cold"
    [ -n "$RECACHE" ] && CACHE_TXT="cold $(fmt_k "$RECACHE")"
    CACHE_SEG=" "$'\033[36m'"${ICON_COLD} ${CACHE_TXT}${RESET}"
  else
    if [ "$LEFT" -ge 600 ]; then
      CACHE_TXT="$((LEFT / 60))m"
    else
      CACHE_TXT=$(printf '%d:%02d' $((LEFT / 60)) $((LEFT % 60)))
    fi
    if [ $((LEFT * 5)) -lt "$TTL_S" ]; then CACHE_COLOR=$'\033[33m'; else CACHE_COLOR=$DIM; fi
    CACHE_SEG=" ${CACHE_COLOR}${ICON_CACHE} ${CACHE_TXT}${RESET}"
  fi
fi

# Prompts sent: plain-text user rows, less meta rows, compaction summaries and
# slash-command echoes.
TRANSCRIPT=$(echo "$input" | jq -r '.transcript_path // empty')
TURNS=0
[ -f "$TRANSCRIPT" ] && TURNS=$(grep '"type":"user"' "$TRANSCRIPT" | grep -v '"tool_result"' | jq -s '
  map(select(.isMeta != true and .isCompactSummary != true
    and (.message.content | type) == "string"
    and (.message.content | test("^(<|/)") | not))) | length')

# Compaction advice: fold glyph and ">N" once compacting now beats continuing on a warm cache
# within N more prompts. Assumes a 15K summary plus effort-scaled thinking, 20K
# re-attached files, 7K context growth per request.
ADVICE_TXT=""
CTX=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
if [ "${CACHE_TXT%% *}" = "cold" ]; then
  [ "$CTX" -ge 100000 ] && ADVICE_TXT="/clear"
else
  ADVICE_TXT=$(awk -v m="$(echo "$input" | jq -r '.model.id // ""')" -v c="$CTX" \
    -v e="$(echo "$input" | jq -r '.effort.level // "high"')" -v ttl="$CACHE_TTL" \
    -v req="$(echo "$input" | jq -r '.prompt_cache.requests // 0')" -v t="$TURNS" '
    function px(p,  b, o, r) {
      if (m ~ /fable|mythos/) { b = 10; o = 50; r = 0.025 }
      else if (m ~ /opus-5-5/) { b = 4; o = 20; r = 0.05 }
      else if (m ~ /opus/) { b = 5; o = 25; r = 0.1 }
      else if (m ~ /sonnet-5/) { b = 2; o = 10; r = 0.1 }
      else if (m ~ /sonnet/) { b = 3; o = 15; r = 0.1 }
      else if (m ~ /haiku-5-5/) { b = p <= 100000 ? 0.1 : 0.5; o = b * 5; r = 0.1 }
      else if (m ~ /haiku/) { b = 1; o = 5; r = 0.1 }
      else return 0
      R = b * r; W = b * (ttl == "1h" ? 2 : 1.25); O = o; return 1
    }
    function run(n, compact,  cost, s, i) {
      s = c
      if (compact) {
        px(c); cost = c * R + (15000 + think) * O
        s = 65000; px(s); cost += 35000 * W + 30000 * R
      }
      for (i = 0; i < n; i++) { px(s + 7000); cost += s * R + 7000 * W + 2000 * O; s += 7000 }
      return cost
    }
    BEGIN {
      if (c <= 65000 || !px(c)) exit
      split("low 2000 medium 5000 high 10000 xhigh 15000 max 20000", a, " ")
      think = 10000; for (i = 1; i < 10; i += 2) if (a[i] == e) think = a[i + 1]
      perPrompt = (t > 0 && req > 0) ? req / t : 1
      for (n = 1; n <= 400; n++) if (run(n, 1) <= run(n, 0)) {
        p = int((n + perPrompt - 1) / perPrompt); if (p <= 50) printf ">%d", p; exit
      }
    }')
fi

# Worktree name. workspace.git_worktree covers any linked worktree; worktree.name
# only appears in --worktree sessions, so fall back to it.
WT=$(echo "$input" | jq -r '.workspace.git_worktree // .worktree.name // empty')

# Branch is read from the live cwd rather than the session JSON, so it stays correct
# after a mid-session cd into a worktree.
BRANCH=$(git -C "${DIR:-.}" rev-parse --abbrev-ref HEAD 2>/dev/null)
if [ "$BRANCH" = "HEAD" ]; then  # detached: show the short sha instead
  BRANCH=$(git -C "${DIR:-.}" rev-parse --short HEAD 2>/dev/null)
fi

DIRNAME=${DIR##*/}

# Branch and directory are the elastic segments, and they absorb whatever overflow
# would otherwise clip the context meter off the right edge. SHADOW is an ASCII
# stand-in for the rest of the line, one char per rendered column, which makes
# ${#SHADOW} a column count. MARGIN covers the nerd-font glyphs that some terminals
# draw double width, and keeps the meter a step in from the edge.
MARGIN=3
SHADOW_BAR=$(printf '%*s' "$SEGMENTS" '')
SHADOW="X ${MODEL} X "
[ -n "$BRANCH" ] && SHADOW="${SHADOW} X "   # git glyph and its spaces, branch aside
SHADOW="${SHADOW} ${SHADOW_BAR} ${PCT}% (${USED_H}/${SIZE_H})"
[ -n "$CACHE_TXT" ] && SHADOW="${SHADOW} X ${CACHE_TXT}"
SHADOW="${SHADOW} X ${TURNS}"
[ -n "$ADVICE_TXT" ] && SHADOW="${SHADOW} X ${ADVICE_TXT}"
BUDGET=$((COLS - ${#SHADOW} - MARGIN))      # columns left for directory and branch

# The branch gives way first, since the directory is the shorter, steadier label.
if [ -n "$BRANCH" ]; then
  ROOM=$((BUDGET - ${#DIRNAME}))
  if [ "$ROOM" -lt 8 ]; then
    BRANCH=""  # too tight for a stub worth reading
  elif [ "${#BRANCH}" -gt "$ROOM" ]; then
    BRANCH="${BRANCH:0:$((ROOM - 1))}…"
  fi
fi

# Narrow terminals, where dropping the branch alone still is not enough.
ROOM=$((BUDGET - ${#BRANCH}))
if [ "${#DIRNAME}" -gt "$ROOM" ]; then
  if [ "$ROOM" -ge 4 ]; then DIRNAME="${DIRNAME:0:$((ROOM - 1))}…"; else DIRNAME=""; fi
fi

# In a worktree, mark the branch with the fork glyph instead of the branch glyph.
GIT_SEG=""
if [ -n "$BRANCH" ]; then
  if [ -n "$WT" ]; then
    GIT_SEG=" ${ICON_WT} ${BRANCH}"
  else
    GIT_SEG=" ${ICON_GIT} ${BRANCH}"
  fi
fi

TURN_SEG=" ${DIM}${ICON_TURNS} ${TURNS}${RESET}"
[ "${ADVICE_TXT#>}" != "$ADVICE_TXT" ] && ADVICE_TXT="${ICON_FOLD} ${ADVICE_TXT}"
[ -n "$ADVICE_TXT" ] && TURN_SEG="${TURN_SEG} "$'\033[33m'"${ADVICE_TXT}${RESET}"

printf '%s%s %s %s %s%s%s %s%s%s %s%% %s(%s/%s)%s%s%s\n' \
  "$DIM" "$ICON_MODEL" "$MODEL" "$ICON_DIR" "$DIRNAME" "$GIT_SEG" "$RESET" \
  "$COLOR" "$BAR" "$RESET" "$PCT" \
  "$DIM" "$USED_H" "$SIZE_H" "$RESET" "$CACHE_SEG" "$TURN_SEG"
