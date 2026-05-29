#!/bin/zsh

set -e

PROFILES=(
  "super-admin"
  "Serve-Admin-103639821168"
)

usage() {
  echo "Usage: $(basename "$0") <profile>"
  echo ""
  echo "Valid profiles:"
  for p in "${PROFILES[@]}"; do
    echo "  - $p"
  done
}

if [[ -z "$1" || "$1" == "-h" || "$1" == "--help" ]]; then
  usage
  exit 0
fi

PROFILE="$1"

if [[ ! " ${PROFILES[*]} " == *" ${PROFILE} "* ]]; then
  echo "Invalid profile: $PROFILE"
  echo ""
  usage
  exit 1
fi

# Log out just incase on dev account
aws sso logout

# Login with chosen profile
mryum aws login --profile="$PROFILE"
mryum aws eks --profile="$PROFILE"
# Don't know why below don't work
# mryum shell --profile="$PROFILE"

echo '⁉️⚠️ℹ️ MUST RUN BELOW MANUALLY'
echo '-----------------------------'
echo "eval \$(mryum export --profile=$PROFILE)"
