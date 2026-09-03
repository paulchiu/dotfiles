#!/bin/bash
# Daily launchd entry point: brew upgrade, then regenerate the zsh caches that
# depend on the upgraded binaries. Deliberately not `&&` chained, so a brew
# failure (a cask needing sudo has no tty here) still leaves the caches fresh.
# Anything that fails or overruns raises a macOS notification, since a 02:56 run
# has nobody watching the terminal.

STATE_DIR="$HOME/.local/state/brew-upgrade"
TIMEOUT=/opt/homebrew/bin/timeout

# Generous: a big cask download on a bad morning is slow but still worth having.
# Past that it is wedged, not slow, and should be killed so the caches still run.
BREW_LIMIT=30m
CACHE_LIMIT=5m

mkdir -p "$STATE_DIR"
date
status=0
failures=()

notify() {
  /usr/bin/osascript \
    -e 'on run argv' \
    -e 'display notification (item 1 of argv) with title (item 2 of argv) subtitle (item 3 of argv)' \
    -e 'end run' \
    "$1" "brew maintenance" "$(date '+%a %-d %b %H:%M')" >/dev/null 2>&1
}

# Runs one step under a wall-clock limit, keeping its own log so the failure
# reason can be classified. Appends a human-readable cause to `failures`.
run_step() {
  local label=$1 limit=$2 script=$3
  local log="$STATE_DIR/$label.log" rc

  "$TIMEOUT" --kill-after=1m "$limit" "$script" 2>&1 | tee "$log"
  rc=${PIPESTATUS[0]}
  [ "$rc" = 0 ] && return 0

  status=$rc
  local reason
  case "$rc" in
    124|137) reason="$label timed out after $limit" ;;
    *)
      if grep -qiE 'sudo:|password is required|no tty present|askpass' "$log"; then
        reason="$label needs sudo"
      else
        reason="$label failed ($rc)"
      fi
      ;;
  esac
  failures+=("$reason")
  echo "$reason" >&2
}

run_step brew "$BREW_LIMIT" "$HOME/bin/brew-upgrade.sh"
run_step zsh-caches "$CACHE_LIMIT" "$HOME/bin/zsh-refresh-caches.sh"

if [ ${#failures[@]} -gt 0 ]; then
  notify "$(IFS=$'\n'; echo "${failures[*]}"). Logs in $STATE_DIR"
fi

exit "$status"
