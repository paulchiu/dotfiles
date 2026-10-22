#!/bin/sh
# Restore Vorssaint text snippets from vorssaint-snippets.json (written by update.sh).
#
# Vorssaint stores snippets as a JSON blob in its prefs plist, next to machine-specific
# state, so only the snippets are tracked. The app is quit first because it rewrites
# its prefs from memory and would overwrite the restored value.

set -eu
cd "$(dirname "$0")"

SNIPPETS="vorssaint-snippets.json"

osascript -e 'quit app "Vorssaint"'
while pgrep -qf 'Vorssaint.app/Contents/MacOS'; do sleep 0.5; done

defaults write com.vorssaint.utils textSnippets -data "$(xxd -p "$SNIPPETS" | tr -d '\n')"

open -gj -a Vorssaint
