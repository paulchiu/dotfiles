#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: agent_loop.sh <codex|claude> <workdir>" >&2
  exit 1
fi

ROLE="$1"
WORKDIR="${2%/}"
MAIL_DIR="${MAIL_DIR:-.nex-mail}"
POLL_INTERVAL="${POLL_INTERVAL:-2}"
CODEX_FLAGS="${CODEX_FLAGS:---dangerously-bypass-approvals-and-sandbox}"
CLAUDE_FLAGS="${CLAUDE_FLAGS:---dangerously-skip-permissions}"

if [[ ! -d "$WORKDIR" ]]; then
  echo "Workdir does not exist: $WORKDIR" >&2
  exit 1
fi

read_flags() {
  local raw="$1"
  local -n out_ref="$2"
  read -r -a out_ref <<< "$raw"
}

hash_file() {
  shasum -a 256 "$1" | awk '{print $1}'
}

build_prompt() {
  local role="$1"
  local peer="$2"
  local inbox_path="$3"
  local outbox_path="$4"
  local message="$5"

  cat <<EOF
You are $role in a two-agent Nex bridge.
Peer agent: $peer.

Rules:
- Read the inbox message below.
- Write exactly one reply suitable for the peer inbox.
- Keep the reply short and action-oriented.
- Output only the reply body.
- If the inbox is empty, output NO_MESSAGE.

Inbox path: $inbox_path
Outbox path: $outbox_path

Inbox message:
$message
EOF
}

case "$ROLE" in
  codex)
    PEER="CLAUDE"
    INBOX="$WORKDIR/$MAIL_DIR/to-codex.md"
    OUTBOX="$WORKDIR/$MAIL_DIR/to-claude.md"
    ROLE_FLAGS="$CODEX_FLAGS"
    ;;
  claude)
    PEER="CODEX"
    INBOX="$WORKDIR/$MAIL_DIR/to-claude.md"
    OUTBOX="$WORKDIR/$MAIL_DIR/to-codex.md"
    ROLE_FLAGS="$CLAUDE_FLAGS"
    ;;
  *)
    echo "Role must be codex or claude." >&2
    exit 1
    ;;
esac

mkdir -p "$WORKDIR/$MAIL_DIR"
touch "$INBOX" "$OUTBOX"

read_flags "$ROLE_FLAGS" FLAG_ARR

LAST_HASH=""

printf '[%s] polling %s every %ss\n' "$ROLE" "$INBOX" "$POLL_INTERVAL"

while true; do
  if [[ -s "$INBOX" ]]; then
    CURRENT_HASH="$(hash_file "$INBOX")"

    if [[ "$CURRENT_HASH" != "$LAST_HASH" ]]; then
      MESSAGE="$(cat "$INBOX")"
      PROMPT_FILE="$(mktemp)"
      OUTBOX_TMP="$(mktemp)"

      build_prompt "${ROLE^^}" "$PEER" "$INBOX" "$OUTBOX" "$MESSAGE" >"$PROMPT_FILE"

      printf '\n[%s] %s processing inbox at %s\n' "$ROLE" "$(date '+%H:%M:%S')" "$INBOX"

      if [[ "$ROLE" == "codex" ]]; then
        codex exec "${FLAG_ARR[@]}" -C "$WORKDIR" -o "$OUTBOX_TMP" - <"$PROMPT_FILE"
      else
        claude "${FLAG_ARR[@]}" -p <"$PROMPT_FILE" >"$OUTBOX_TMP"
      fi

      mv "$OUTBOX_TMP" "$OUTBOX"
      LAST_HASH="$CURRENT_HASH"

      rm -f "$PROMPT_FILE"

      printf '[%s] wrote reply to %s\n' "$ROLE" "$OUTBOX"
    fi
  fi

  sleep "$POLL_INTERVAL"
done
