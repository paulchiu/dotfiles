#!/usr/bin/env bash
# Helper script to parse GitHub PR URLs and deduplicate by repo
# Usage: parse-pr-urls.sh "text with urls"
# Output: org/repo#number (one per line, deduplicated by repo)

INPUT="${1:-}"

# If no input provided via argument, read from stdin
if [[ -z "$INPUT" ]]; then
	INPUT=$(cat)
fi

# Use a file to track seen repos (macOS bash compatible)
SEEN_FILE=$(mktemp)
trap "rm -f $SEEN_FILE" EXIT

# Extract URLs and process them
echo "$INPUT" | grep -oE 'https://github\.com/[^/]+/[^/]+/pull/[0-9]+' | while IFS= read -r url; do
	# Parse URL: https://github.com/{org}/{repo}/pull/{number}
	org=$(echo "$url" | sed -E 's|https://github\.com/([^/]+)/.*|\1|')
	repo=$(echo "$url" | sed -E 's|https://github\.com/[^/]+/([^/]+)/pull/.*|\1|')
	number=$(echo "$url" | sed -E 's|.*/pull/([0-9]+).*|\1|')

	# Deduplicate: only output first PR for each repo
	if ! grep -q "^$repo$" "$SEEN_FILE" 2>/dev/null; then
		echo "$repo" >>"$SEEN_FILE"
		echo "$org/$repo#$number"
	fi
done
