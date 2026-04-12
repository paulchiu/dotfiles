#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${NEX_PANE_ID:-}" ]]; then
  echo "test_panes.sh must run inside a Nex pane." >&2
  exit 1
fi

if ! command -v nex >/dev/null 2>&1; then
  echo "Missing required command: nex" >&2
  exit 1
fi

send_line() {
  local pane="$1"
  local text="$2"

  nex pane send --to "$pane" "$(printf '%s\r' "$text")"
}

if [[ ! -S /tmp/nex.sock ]]; then
  echo "Nex socket not found at /tmp/nex.sock." >&2
  echo "The CLI will silently no-op if Nex is not reachable." >&2
  exit 1
fi

MODE="${1:-siblings}"
WORKDIR="${2:-$PWD}"
WORKDIR="${WORKDIR%/}"
BASE_NAME="${BASE_NAME:-nex-test-$$}"
COORDINATOR_NAME="${COORDINATOR_NAME:-${BASE_NAME}-coordinator}"
PANE_A_NAME="${PANE_A_NAME:-${BASE_NAME}-a}"
PANE_B_NAME="${PANE_B_NAME:-${BASE_NAME}-b}"
SPLIT_DELAY="${SPLIT_DELAY:-2}"

if [[ ! -d "$WORKDIR" ]]; then
  echo "Workdir does not exist: $WORKDIR" >&2
  exit 1
fi

make_loop_cmd() {
  local label="$1"
  local color="$2"

  printf "cd %q && bash -lc %q" "$WORKDIR" \
    "clear; printf '\\n\\033[1;${color}m${label}\\033[0m\\n'; printf 'cwd: %s\\n\\n' '$WORKDIR'; while true; do date; sleep 2; done"
}

printf -v PANE_A_CMD '%s' "$(make_loop_cmd "Pane A: ${PANE_A_NAME}" 32)"
printf -v PANE_B_CMD '%s' "$(make_loop_cmd "Pane B: ${PANE_B_NAME}" 36)"
printf -v CREATE_PANE_B_FROM_A_CMD 'cd %q && nex pane split --name %q --direction vertical --path %q' \
  "$WORKDIR" "$PANE_B_NAME" "$WORKDIR"

nex pane name "$COORDINATOR_NAME"
nex event notification --title "Nex test" --body "Starting pane smoke test: $MODE"
sleep 1

case "$MODE" in
  siblings)
    nex pane split --name "$PANE_A_NAME" --direction horizontal --path "$WORKDIR"
    sleep "$SPLIT_DELAY"
    nex pane split --name "$PANE_B_NAME" --direction horizontal --path "$WORKDIR"
    sleep "$SPLIT_DELAY"
    nex layout select tiled
    ;;
  nested)
    nex pane split --name "$PANE_A_NAME" --direction horizontal --path "$WORKDIR"
    sleep "$SPLIT_DELAY"
    send_line "$PANE_A_NAME" "$CREATE_PANE_B_FROM_A_CMD"
    sleep "$SPLIT_DELAY"
    ;;
  *)
    echo "Usage: test_panes.sh [siblings|nested] [workdir]" >&2
    exit 1
    ;;
esac

sleep 1
send_line "$PANE_A_NAME" "$PANE_A_CMD"
sleep 1
send_line "$PANE_B_NAME" "$PANE_B_CMD"

cat <<EOF
Created Nex test panes.
- mode: $MODE
- coordinator pane: $COORDINATOR_NAME
- pane A: $PANE_A_NAME
- pane B: $PANE_B_NAME

Run this first:
  ./scripts/test_panes.sh siblings $WORKDIR

Then try:
  ./scripts/test_panes.sh nested $WORKDIR

If you can see the date loop in both panes, pane creation works and the remaining issue is in agent startup.
EOF
