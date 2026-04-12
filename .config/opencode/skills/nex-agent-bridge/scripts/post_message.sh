#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "Usage: post_message.sh <codex|claude> <message-file|-> [workdir]" >&2
  exit 1
fi

TARGET="$1"
SOURCE="$2"
WORKDIR="${3:-$PWD}"
WORKDIR="${WORKDIR%/}"
MAIL_DIR="${MAIL_DIR:-.nex-mail}"

case "$TARGET" in
  codex)
    INBOX="$WORKDIR/$MAIL_DIR/to-codex.md"
    ;;
  claude)
    INBOX="$WORKDIR/$MAIL_DIR/to-claude.md"
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

echo "Posted message to $TARGET. The agent loop will pick it up on the next poll."
