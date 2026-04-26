#!/bin/sh
# Helper for the starship custom.aws module.
#   `aws-status.sh check` exits 0 if there is an active AWS session, else 1.
#   `aws-status.sh print` prints "☁️  <profile> (<region>) [<remaining>]" for the prompt.

mode=${1:-print}
now_ts=$(date -u +%s)
best_exp=

for f in "$HOME"/.aws/sso/cache/*.json; do
  [ -f "$f" ] || continue
  grep -q '"accessToken"' "$f" || continue
  exp=$(sed -n 's/.*"expiresAt"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$f")
  [ -n "$exp" ] || continue
  exp_ts=$(date -j -u -f "%Y-%m-%dT%H:%M:%SZ" "$exp" +%s 2>/dev/null) || continue
  [ "$exp_ts" -le "$now_ts" ] && continue
  if [ -z "$best_exp" ] || [ "$exp_ts" -gt "$best_exp" ]; then
    best_exp=$exp_ts
  fi
done

has_env_session=
if [ -n "$AWS_SESSION_TOKEN" ] || [ -n "$AWS_ACCESS_KEY_ID" ]; then
  has_env_session=1
fi

if [ -z "$best_exp" ] && [ -z "$has_env_session" ]; then
  exit 1
fi

[ "$mode" = check ] && exit 0

if [ -n "$best_exp" ]; then
  remaining=$((best_exp - now_ts))
  h=$((remaining / 3600))
  m=$(((remaining % 3600) / 60))
  if [ "$h" -gt 0 ]; then
    printf '☁️  %s (%s) [%dh%dm]' "$AWS_PROFILE" "$AWS_REGION" "$h" "$m"
  else
    printf '☁️  %s (%s) [%dm]' "$AWS_PROFILE" "$AWS_REGION" "$m"
  fi
else
  printf '☁️  %s (%s)' "$AWS_PROFILE" "$AWS_REGION"
fi
