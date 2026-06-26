#!/bin/sh
# Regenerate the Homebrew Brewfile and /Applications inventory.
#
# `brew bundle dump` re-adds every installed cask, including apps that ship their
# own privileged auto-updaters (browsers, Office, Zoom, Google Drive). Letting
# Homebrew manage those causes repeated sudo prompts on `brew upgrade`, because the
# updater resets the .app bundle to root:wheel and brew then has to re-elevate to
# move it. The exclusion list lives in brew-self-managed.txt; we strip those casks
# from each fresh dump and re-append the list to the Brewfile as documentation.

set -eu
cd "$(dirname "$0")"

BREWFILE="Brewfile"
EXCLUDE="brew-self-managed.txt"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

# 1. Dump current state to a temp file (description comments are on by default).
brew bundle dump --force --file="$TMP"

# 2. Collect the excluded cask tokens from the exclusion file (tolerates the
#    leading "# " since the lines are commented in that file).
EXCL_TOKENS="$(awk -F'"' '/^#?[[:space:]]*cask "/ { print $2 }' "$EXCLUDE" | tr '\n' ' ')"

# 3. Write the Brewfile, dropping each excluded cask and its describe comment.
awk -v excl="$EXCL_TOKENS" '
  BEGIN { n = split(excl, a, " "); for (i = 1; i <= n; i++) ex[a[i]] = 1 }
  /^cask "/ {
    tok = $0; sub(/^cask "/, "", tok); sub(/".*/, "", tok)
    if (tok in ex) { pend = ""; next }          # drop the cask and any held comment
  }
  /^#/ { if (pend != "") print pend; pend = $0; next }   # hold a comment line
  { if (pend != "") { print pend; pend = "" } print }    # flush held comment, then print
  END { if (pend != "") print pend }
' "$TMP" > "$BREWFILE"

# 4. Re-append the self-managed list so the Brewfile records what was excluded.
printf '\n# === Self-managed apps (excluded from the bundle above) ===\n' >> "$BREWFILE"
cat "$EXCLUDE" >> "$BREWFILE"

# 5. Refresh the installed-apps inventory.
ls /Applications > mac-apps.txt
