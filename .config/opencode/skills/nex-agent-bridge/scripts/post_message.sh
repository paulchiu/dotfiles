#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${NEX_PANE_ID:-}" ]]; then
  echo "post_message.sh must run inside a Nex pane." >&2
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

if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "Usage: post_message.sh <codex|claude> <message-file|-> [workdir]" >&2
  exit 1
fi

TARGET="$1"
SOURCE="$2"
WORKDIR="${3:-$PWD}"
WORKDIR="${WORKDIR%/}"
MAIL_DIR="${MAIL_DIR:-.nex-mail}"
CODEX_NAME="${CODEX_NAME:-codex}"
CLAUDE_NAME="${CLAUDE_NAME:-claude}"

case "$TARGET" in
  codex)
    INBOX="$WORKDIR/$MAIL_DIR/to-codex.md"
    PANE="$CODEX_NAME"
    ;;
  claude)
    INBOX="$WORKDIR/$MAIL_DIR/to-claude.md"
    PANE="$CLAUDE_NAME"
    ;;
  *)
    echo "Target must be codex or claude." >&2
    exit 1
    ;;
esac

mkdir -p "$WORKDIR/$MAIL_DIR"

if [[ "$SOURCE" == "-" ]]; then
  cat >"$INBOX"
else
  cp "$SOURCE" "$INBOX"
fi

send_line "$PANE" CHECK_INBOX

echo "Posted message to $TARGET and sent CHECK_INBOX."
