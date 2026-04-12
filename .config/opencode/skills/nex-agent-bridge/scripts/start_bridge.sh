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

WORKDIR="${1:-$PWD}"
WORKDIR="${WORKDIR%/}"
MAIL_DIR="${MAIL_DIR:-.nex-mail}"
COORDINATOR_NAME="${COORDINATOR_NAME:-coordinator}"
CODEX_NAME="${CODEX_NAME:-codex}"
CLAUDE_NAME="${CLAUDE_NAME:-claude}"
SPLIT_DELAY="${SPLIT_DELAY:-2}"

if [[ ! -d "$WORKDIR" ]]; then
  echo "Workdir does not exist: $WORKDIR" >&2
  exit 1
fi

MAIL_PATH="$WORKDIR/$MAIL_DIR"
mkdir -p "$MAIL_PATH"
: >"$MAIL_PATH/to-codex.md"
: >"$MAIL_PATH/to-claude.md"

read -r -d '' CODEX_PROMPT <<EOF || true
You are CODEX in a two-agent Nex bridge.
Peer agent: CLAUDE.

Protocol:
- Your inbox is $MAIL_DIR/to-codex.md
- Your outbox is $MAIL_DIR/to-claude.md
- When you receive CHECK_INBOX, read your inbox, write exactly one reply to your outbox, then stop.
- If the inbox is empty, reply with NO_MESSAGE.
- Do not send raw text directly to the other pane.
- Keep replies short and action-oriented.

Reply with READY and wait for further messages.
EOF

read -r -d '' CLAUDE_PROMPT <<EOF || true
You are CLAUDE in a two-agent Nex bridge.
Peer agent: CODEX.

Protocol:
- Your inbox is $MAIL_DIR/to-claude.md
- Your outbox is $MAIL_DIR/to-codex.md
- When you receive CHECK_INBOX, read your inbox, write exactly one reply to your outbox, then stop.
- If the inbox is empty, reply with NO_MESSAGE.
- Do not send raw text directly to the other pane.
- Keep replies short and action-oriented.

Reply with READY and wait for further messages.
EOF

printf -v CODEX_CMD 'cd %q && codex --no-alt-screen -C %q %q' "$WORKDIR" "$WORKDIR" "$CODEX_PROMPT"
printf -v CLAUDE_CMD 'cd %q && claude %q' "$WORKDIR" "$CLAUDE_PROMPT"

nex pane name "$COORDINATOR_NAME"
nex pane split --name "$CODEX_NAME" --direction vertical --path "$WORKDIR"
sleep "$SPLIT_DELAY"
nex pane split --name "$CLAUDE_NAME" --direction horizontal --path "$WORKDIR"
sleep "$SPLIT_DELAY"

nex pane send --to "$CODEX_NAME" "$CODEX_CMD"
sleep 1
nex pane send --to "$CLAUDE_NAME" "$CLAUDE_CMD"

cat <<EOF
Bridge started in $WORKDIR
- coordinator pane: $COORDINATOR_NAME
- codex pane: $CODEX_NAME
- claude pane: $CLAUDE_NAME
- mail dir: $MAIL_DIR

Send work with:
  printf '%s\n' 'Your message' | ./scripts/post_message.sh codex -
  printf '%s\n' 'Your message' | ./scripts/post_message.sh claude -
EOF
