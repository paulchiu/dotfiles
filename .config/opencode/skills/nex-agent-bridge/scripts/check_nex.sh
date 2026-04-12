#!/usr/bin/env bash
set -euo pipefail

echo "NEX_PANE_ID=${NEX_PANE_ID:-unset}"
echo "nex=$(command -v nex || echo missing)"

if [[ -S /tmp/nex.sock ]]; then
  echo "socket=/tmp/nex.sock"
else
  echo "socket missing: /tmp/nex.sock"
  exit 1
fi

nex event notification --title "Nex connectivity check" --body "If you see this, the CLI can reach Nex."
echo "Sent notification request."

NAME="nex-check-$$"
nex pane name "$NAME"
echo "Requested current pane rename to: $NAME"

cat <<'EOF'
Expected visible signals:
- a Nex notification saying "Nex connectivity check"
- the current pane title changes to the generated nex-check-* name

If neither happens, the CLI is not controlling the visible Nex app from this shell.
EOF
