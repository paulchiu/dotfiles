#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${NEX_PANE_ID:-}" ]]; then
  echo "start_bridge.sh must run inside a Nex pane." >&2
  exit 1
fi

for cmd in nex codex claude sqlite3 python3; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd" >&2
    exit 1
  fi
done

send_line() {
  local pane="$1"
  local text="$2"

  nex pane send --to "$pane" "$(printf '%s\r' "$text")"
}

render_log_tail_cmd() {
  local role="$1"
  local log_file="$2"

  printf "cd %q && clear && printf %q && touch %q && tail -n +1 -F %q" \
    "$WORKDIR" \
    "bridge worker: ${role}\nlog: ${log_file}\n\n" \
    "$log_file" \
    "$log_file"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

WORKDIR="${1:-$PWD}"
WORKDIR="${WORKDIR%/}"
MAIL_DIR="${MAIL_DIR:-.nex-mail}"
COORDINATOR_NAME="${COORDINATOR_NAME:-coordinator}"
CODEX_NAME="${CODEX_NAME:-codex}"
CLAUDE_NAME="${CLAUDE_NAME:-claude}"
CODEX_FLAGS="${CODEX_FLAGS:---dangerously-bypass-approvals-and-sandbox}"
CLAUDE_FLAGS="${CLAUDE_FLAGS:---dangerously-skip-permissions}"
POLL_INTERVAL="${POLL_INTERVAL:-2}"
SPLIT_DELAY="${SPLIT_DELAY:-2}"
LAYOUT_TEMPLATE="${LAYOUT_TEMPLATE:-$WORKDIR/.nex-bridge-layout.json}"
WORKER_MODE="${WORKER_MODE:-pane}"
ROOT_DIRECTION="${ROOT_DIRECTION:-}"
WORKER_DIRECTION="${WORKER_DIRECTION:-}"
WORKER_ORDER="${WORKER_ORDER:-}"
ROOT_RATIO="${ROOT_RATIO:-}"
WORKER_RATIO="${WORKER_RATIO:-}"

if [[ ! -d "$WORKDIR" ]]; then
  echo "Workdir does not exist: $WORKDIR" >&2
  exit 1
fi

if [[ "$WORKER_MODE" != "background" && "$WORKER_MODE" != "pane" ]]; then
  echo "WORKER_MODE must be background or pane." >&2
  exit 1
fi

ROOT_DIRECTION="${ROOT_DIRECTION:-horizontal}"
WORKER_DIRECTION="${WORKER_DIRECTION:-vertical}"
WORKER_ORDER="${WORKER_ORDER:-$CLAUDE_NAME,$CODEX_NAME}"
ROOT_RATIO="${ROOT_RATIO:-0.42}"
WORKER_RATIO="${WORKER_RATIO:-0.5}"

IFS=, read -r FIRST_WORKER SECOND_WORKER <<<"$WORKER_ORDER"

if [[ -z "${FIRST_WORKER:-}" || -z "${SECOND_WORKER:-}" ]]; then
  echo "WORKER_ORDER must contain two comma-separated pane labels." >&2
  exit 1
fi

MAIL_PATH="$WORKDIR/$MAIL_DIR"
mkdir -p "$MAIL_PATH"
: >"$MAIL_PATH/to-codex.md"
: >"$MAIL_PATH/to-claude.md"

printf -v SECOND_WORKER_CMD 'cd %q && clear && printf %q && exec env MAIL_DIR=%q POLL_INTERVAL=%q CODEX_FLAGS=%q CLAUDE_FLAGS=%q %q %q %q' \
  "$WORKDIR" "bridge worker: ${SECOND_WORKER}\nmode: pane\n\n" "$MAIL_DIR" "$POLL_INTERVAL" "$CODEX_FLAGS" "$CLAUDE_FLAGS" "$SCRIPT_DIR/agent_loop.sh" "$SECOND_WORKER" "$WORKDIR"
printf -v FIRST_WORKER_CMD 'cd %q && clear && printf %q && exec env MAIL_DIR=%q POLL_INTERVAL=%q CODEX_FLAGS=%q CLAUDE_FLAGS=%q %q %q %q' \
  "$WORKDIR" "bridge worker: ${FIRST_WORKER}\nmode: pane\n\n" "$MAIL_DIR" "$POLL_INTERVAL" "$CODEX_FLAGS" "$CLAUDE_FLAGS" "$SCRIPT_DIR/agent_loop.sh" "$FIRST_WORKER" "$WORKDIR"

nex pane name "$COORDINATOR_NAME"
nex pane split --name "$SECOND_WORKER" --direction "$ROOT_DIRECTION" --path "$WORKDIR"
sleep "$SPLIT_DELAY"
nex pane split --name "$FIRST_WORKER" --direction "$ROOT_DIRECTION" --path "$WORKDIR"
sleep "$SPLIT_DELAY"

"$SCRIPT_DIR/apply_layout.sh" "$LAYOUT_TEMPLATE"
sleep 1

if [[ "$WORKER_MODE" == "background" ]]; then
  "$SCRIPT_DIR/stop_workers.sh" "$WORKDIR" >/dev/null 2>&1 || true
  "$SCRIPT_DIR/start_workers.sh" "$WORKDIR"

  CODEX_LOG="$MAIL_PATH/codex.log"
  CLAUDE_LOG="$MAIL_PATH/claude.log"
  CODEX_VIEW_CMD="$(render_log_tail_cmd codex "$CODEX_LOG")"
  CLAUDE_VIEW_CMD="$(render_log_tail_cmd claude "$CLAUDE_LOG")"

  send_line "$CODEX_NAME" "$CODEX_VIEW_CMD"
  sleep 1
  send_line "$CLAUDE_NAME" "$CLAUDE_VIEW_CMD"
else
  send_line "$SECOND_WORKER" "$SECOND_WORKER_CMD"
  sleep 1
  send_line "$FIRST_WORKER" "$FIRST_WORKER_CMD"
fi

cat <<EOF
Bridge started in $WORKDIR
- coordinator pane: $COORDINATOR_NAME
- codex pane: $CODEX_NAME
- claude pane: $CLAUDE_NAME
- worker mode: $WORKER_MODE
- mail dir: $MAIL_DIR
- codex flags: $CODEX_FLAGS
- claude flags: $CLAUDE_FLAGS
- poll interval: $POLL_INTERVAL
- root split direction: $ROOT_DIRECTION
- worker split direction: $WORKER_DIRECTION
- root ratio: $ROOT_RATIO
- worker ratio: $WORKER_RATIO
- worker order: $FIRST_WORKER,$SECOND_WORKER
EOF

if [[ -f "$LAYOUT_TEMPLATE" ]]; then
  printf '%s\n' "- layout template: $LAYOUT_TEMPLATE"
fi

cat <<EOF

Send work with:
  printf '%s\n' 'Your message' | ./scripts/post_message.sh codex -
  printf '%s\n' 'Your message' | ./scripts/post_message.sh claude -
EOF
