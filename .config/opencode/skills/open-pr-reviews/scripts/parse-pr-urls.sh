#!/usr/bin/env bash
# Helper script to parse GitHub PR URLs and deduplicate by URL
# Usage: parse-pr-urls.sh "text with urls"
# Output: org/repo#number (one per line, deduplicated by exact URL)

INPUT="${1:-}"

# If no input provided via argument, read from stdin
if [[ -z "$INPUT" ]]; then
	INPUT=$(cat)
fi

# Use a file to track seen URLs (macOS bash compatible)
SEEN_FILE=$(mktemp)
trap "rm -f $SEEN_FILE" EXIT

# Extract URLs and process them
echo "$INPUT" | grep -oE 'https://github\.com/[^/]+/[^/]+/pull/[0-9]+' | while IFS= read -r url; do
	# Parse URL: https://github.com/{org}/{repo}/pull/{number}
	org=$(echo "$url" | sed -E 's|https://github\.com/([^/]+)/.*|\1|')
	repo=$(echo "$url" | sed -E 's|https://github\.com/[^/]+/([^/]+)/pull/.*|\1|')
	number=$(echo "$url" | sed -E 's|.*/pull/([0-9]+).*|\1|')

	key="$org/$repo#$number"

	# Deduplicate by exact PR (allow multiple PRs from the same repo)
	if ! grep -q "^$key$" "$SEEN_FILE" 2>/dev/null; then
		echo "$key" >>"$SEEN_FILE"
		echo "$key"
	fi
done
