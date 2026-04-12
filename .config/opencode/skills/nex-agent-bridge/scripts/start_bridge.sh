#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${NEX_PANE_ID:-}" ]]; then
  echo "start_bridge.sh must run inside a Nex pane." >&2
  exit 1
fi

for cmd in nex codex claude; do
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
LAYOUT="${LAYOUT:-}"

if [[ ! -d "$WORKDIR" ]]; then
  echo "Workdir does not exist: $WORKDIR" >&2
  exit 1
fi

MAIL_PATH="$WORKDIR/$MAIL_DIR"
mkdir -p "$MAIL_PATH"
: >"$MAIL_PATH/to-codex.md"
: >"$MAIL_PATH/to-claude.md"
printf -v CODEX_CMD 'cd %q && MAIL_DIR=%q POLL_INTERVAL=%q CODEX_FLAGS=%q CLAUDE_FLAGS=%q %q codex %q' \
  "$WORKDIR" "$MAIL_DIR" "$POLL_INTERVAL" "$CODEX_FLAGS" "$CLAUDE_FLAGS" "$SCRIPT_DIR/agent_loop.sh" "$WORKDIR"
printf -v CLAUDE_CMD 'cd %q && MAIL_DIR=%q POLL_INTERVAL=%q CODEX_FLAGS=%q CLAUDE_FLAGS=%q %q claude %q' \
  "$WORKDIR" "$MAIL_DIR" "$POLL_INTERVAL" "$CODEX_FLAGS" "$CLAUDE_FLAGS" "$SCRIPT_DIR/agent_loop.sh" "$WORKDIR"
printf -v CREATE_CLAUDE_PANE_CMD 'cd %q && nex pane split --name %q --direction vertical --path %q' "$WORKDIR" "$CLAUDE_NAME" "$WORKDIR"

nex pane name "$COORDINATOR_NAME"
nex pane split --name "$CODEX_NAME" --direction horizontal --path "$WORKDIR"
sleep "$SPLIT_DELAY"

# Build a nested layout: coordinator on the left, codex/claude stacked on the right.
send_line "$CODEX_NAME" "$CREATE_CLAUDE_PANE_CMD"
sleep "$SPLIT_DELAY"

if [[ -n "$LAYOUT" ]]; then
  nex layout select "$LAYOUT"
  sleep 1
fi

send_line "$CODEX_NAME" "$CODEX_CMD"
sleep 1
send_line "$CLAUDE_NAME" "$CLAUDE_CMD"

cat <<EOF
Bridge started in $WORKDIR
- coordinator pane: $COORDINATOR_NAME
- codex pane: $CODEX_NAME
- claude pane: $CLAUDE_NAME
- mail dir: $MAIL_DIR
- codex flags: $CODEX_FLAGS
- claude flags: $CLAUDE_FLAGS
- poll interval: $POLL_INTERVAL
EOF

if [[ -n "$LAYOUT" ]]; then
  cat <<EOF
- layout override: $LAYOUT
EOF
fi

cat <<EOF

Send work with:
  printf '%s\n' 'Your message' | ./scripts/post_message.sh codex -
  printf '%s\n' 'Your message' | ./scripts/post_message.sh claude -
EOF
