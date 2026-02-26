#!/bin/bash
#
# Bulk comment @dependabot rebase on open Dependabot PRs
#
# Usage: dependabot-rebase.sh <owner/repo>
#

set -euo pipefail

REPO="${1:-}"

if [ -z "$REPO" ]; then
	echo "Error: Repository required"
	echo "Usage: dependabot-rebase.sh <owner/repo>"
	exit 1
fi

echo "Finding open Dependabot PRs in $REPO..."

# Get open Dependabot PRs
PRS=$(gh pr list --repo "$REPO" --state open --author dependabot --json number --jq '.[].number')

if [ -z "$PRS" ]; then
	echo "No open Dependabot PRs found."
	exit 0
fi

# Count PRs
COUNT=$(echo "$PRS" | wc -l | tr -d ' ')
echo "Found $COUNT open Dependabot PR(s)"
echo ""

# Comment on each PR
for PR in $PRS; do
	echo "Commenting on PR #$PR..."
	gh pr comment "$PR" --repo "$REPO" --body "@dependabot rebase"
done

echo ""
echo "Done! Commented on $COUNT PR(s)."
