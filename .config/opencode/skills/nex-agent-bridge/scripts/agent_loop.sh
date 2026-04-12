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

_child_pid=""
_on_exit() { [[ -n "$_child_pid" ]] && kill "$_child_pid" 2>/dev/null || true; }
trap _on_exit EXIT

run_agent() {
  local prompt_file="$1"
  local outbox_tmp="$2"

  if [[ "$ROLE" == "codex" ]]; then
    codex exec "${FLAG_ARR[@]}" -C "$WORKDIR" -o "$outbox_tmp" - <"$prompt_file" &
  else
    claude "${FLAG_ARR[@]}" -p <"$prompt_file" >"$outbox_tmp" &
  fi
  _child_pid=$!
  wait "$_child_pid"
  local rc=$?
  _child_pid=""
  return "$rc"
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

FLAG_ARR=()
read -r -a FLAG_ARR <<< "$ROLE_FLAGS"
LAST_HASH=""
ROLE_UPPER="$(printf '%s' "$ROLE" | tr '[:lower:]' '[:upper:]')"

printf '[%s] polling %s every %ss\n' "$ROLE" "$INBOX" "$POLL_INTERVAL"

while true; do
  if [[ -s "$INBOX" ]]; then
    CURRENT_HASH="$(hash_file "$INBOX")"

    if [[ "$CURRENT_HASH" != "$LAST_HASH" ]]; then
      MESSAGE="$(cat "$INBOX")"
      PROMPT_FILE="$(mktemp)"
      OUTBOX_TMP="$(mktemp)"

      build_prompt "$ROLE_UPPER" "$PEER" "$INBOX" "$OUTBOX" "$MESSAGE" >"$PROMPT_FILE"

      printf '\n[%s] %s processing inbox at %s\n' "$ROLE" "$(date '+%H:%M:%S')" "$INBOX"

      if run_agent "$PROMPT_FILE" "$OUTBOX_TMP"; then
        mv "$OUTBOX_TMP" "$OUTBOX"
        printf '[%s] wrote reply to %s\n' "$ROLE" "$OUTBOX"
      else
        STATUS=$?
        printf '[%s] agent command failed with exit %s\n' "$ROLE" "$STATUS" >&2
        printf 'AGENT_ERROR: %s failed with exit %s. Check .nex-mail/%s.log.\n' \
          "$ROLE_UPPER" "$STATUS" "$ROLE" >"$OUTBOX_TMP"
        mv "$OUTBOX_TMP" "$OUTBOX"
      fi

      LAST_HASH="$CURRENT_HASH"
      rm -f "$PROMPT_FILE"
    fi
  fi

  sleep "$POLL_INTERVAL"
done
