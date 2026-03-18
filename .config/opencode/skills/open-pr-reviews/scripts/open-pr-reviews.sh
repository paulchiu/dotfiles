#!/usr/bin/env bash
set -euo pipefail

# Usage: open-pr-reviews.sh org/repo#number [org/repo#number ...]
# Example: open-pr-reviews.sh mr-yum/manage-frontend#1656 mr-yum/order-api#1256

if [[ $# -eq 0 ]]; then
	echo "Usage: $0 org/repo#number [org/repo#number ...]"
	echo "Example: $0 mr-yum/manage-frontend#1656 mr-yum/order-api#1256"
	exit 1
fi

DEV_DIR="$HOME/dev"
DATE_LABEL=$(date +"%Y-%m-%d")
WORKSPACE_NAME="Reviews $DATE_LABEL"

# --- Find or create workspace ---
find_workspace() {
	cmux list-workspaces 2>/dev/null | while IFS= read -r line; do
		# Each line looks like: workspace:N <UUID> "Title"
		if echo "$line" | grep -qF "$WORKSPACE_NAME"; then
			echo "$line" | awk '{print $1}'
			return
		fi
	done
}

WORKSPACE_REF=$(find_workspace)

if [[ -z "$WORKSPACE_REF" ]]; then
	echo "Creating workspace: $WORKSPACE_NAME"
	WORKSPACE_UUID=$(cmux new-workspace 2>&1 | awk '{print $2}')
	# Need to find the ref for the new workspace
	sleep 0.3
	WORKSPACE_REF=$(find_workspace_by_uuid "$WORKSPACE_UUID" 2>/dev/null || true)
	if [[ -z "$WORKSPACE_REF" ]]; then
		# List workspaces and find the last one (just created)
		WORKSPACE_REF=$(cmux list-workspaces 2>/dev/null | tail -1 | awk '{print $1}')
	fi
	cmux rename-workspace --workspace "$WORKSPACE_REF" "$WORKSPACE_NAME" 2>/dev/null
	cmux select-workspace --workspace "$WORKSPACE_REF" 2>/dev/null
	FIRST_TAB="yes"
else
	echo "Found existing workspace: $WORKSPACE_NAME ($WORKSPACE_REF)"
	cmux select-workspace --workspace "$WORKSPACE_REF" 2>/dev/null
	FIRST_TAB="yes"
fi

# --- List existing tabs in workspace ---
get_existing_tabs() {
	cmux list-pane-surfaces --workspace "$WORKSPACE_REF" 2>/dev/null || true
}

# Extract surface ref from a line like: * surface:35  title  [selected]
# or: surface:35  title
parse_surface_ref() {
	echo "$1" | grep -o 'surface:[0-9]*'
}

find_tab_by_name() {
	local tab_name="$1"
	local result=""
	while IFS= read -r line; do
		if echo "$line" | grep -qF "$tab_name"; then
			result=$(parse_surface_ref "$line")
			break
		fi
	done <<<"$(get_existing_tabs)"
	echo "$result"
}

# --- Send command to a surface and press enter ---
send_cmd() {
	local surface="$1"
	local cmd="$2"
	cmux send --surface "$surface" --workspace "$WORKSPACE_REF" "$cmd" 2>/dev/null
	cmux send-key --surface "$surface" --workspace "$WORKSPACE_REF" enter 2>/dev/null
	sleep 0.5
}

# --- Process each PR ---
FIRST_ITERATION="yes"
for arg in "$@"; do
	# Parse org/repo#number
	ORG=$(echo "$arg" | cut -d'/' -f1)
	REPO_AND_NUM=$(echo "$arg" | cut -d'/' -f2)
	REPO=$(echo "$REPO_AND_NUM" | cut -d'#' -f1)
	PR_NUM=$(echo "$REPO_AND_NUM" | cut -d'#' -f2)

	REPO_DIR="$DEV_DIR/$REPO"
	WORKTREE_DIR="$DEV_DIR/$REPO-pr-$PR_NUM"
	TAB_NAME="$REPO #$PR_NUM"
	PR_URL="https://github.com/$ORG/$REPO/pull/$PR_NUM"

	echo "Processing: $TAB_NAME ($PR_URL)"

	# Get the PR branch name
	BRANCH=$(gh pr view "$PR_URL" --json headRefName -q '.headRefName' 2>/dev/null || true)
	if [[ -z "$BRANCH" ]]; then
		echo "  WARNING: Could not get branch for $PR_URL, skipping"
		continue
	fi
	echo "  Branch: $BRANCH"

	# Clone repo if it doesn't exist
	if [[ ! -d "$REPO_DIR" ]]; then
		echo "  Cloning $ORG/$REPO to $REPO_DIR..."
		gh repo clone "$ORG/$REPO" "$REPO_DIR" 2>/dev/null
	fi

	# Fetch the PR branch into the main clone
	git -C "$REPO_DIR" fetch origin "$BRANCH" 2>/dev/null || true

	# Create or update the worktree for this PR
	if [[ -d "$WORKTREE_DIR" ]]; then
		echo "  Worktree already exists at $WORKTREE_DIR, updating..."
		git -C "$WORKTREE_DIR" fetch origin "$BRANCH" 2>/dev/null || true
		git -C "$WORKTREE_DIR" reset --hard "origin/$BRANCH" 2>/dev/null || true
	else
		echo "  Creating worktree at $WORKTREE_DIR..."
		git -C "$REPO_DIR" worktree add "$WORKTREE_DIR" "origin/$BRANCH" --detach 2>/dev/null || true
		# Checkout the actual branch so gh pr commands work
		git -C "$WORKTREE_DIR" checkout -B "$BRANCH" "origin/$BRANCH" 2>/dev/null || true
	fi

	# Find or create tab
	SURFACE_REF=$(find_tab_by_name "$TAB_NAME")

	if [[ -n "$SURFACE_REF" ]]; then
		echo "  Reusing existing tab: $TAB_NAME ($SURFACE_REF)"
		send_cmd "$SURFACE_REF" "git fetch origin $BRANCH && git reset --hard origin/$BRANCH"
		# Start branch review
		send_cmd "$SURFACE_REF" "claude \"use branch review skill\""
		echo "  Started branch review in: $TAB_NAME"
	else
		if [[ "$FIRST_TAB" == "yes" && "$FIRST_ITERATION" == "yes" ]]; then
			# Use the default tab that comes with the new workspace
			SURFACE_REF=$(parse_surface_ref "$(get_existing_tabs | head -1)")
			echo "  Using default tab: $SURFACE_REF"
		else
			# Create a new tab
			RESULT=$(cmux new-surface --type terminal --workspace "$WORKSPACE_REF" 2>&1)
			SURFACE_REF=$(parse_surface_ref "$RESULT")
			echo "  Created tab: $SURFACE_REF"
			sleep 0.3
		fi

		# Navigate to worktree directory
		send_cmd "$SURFACE_REF" "cd $WORKTREE_DIR"

		# Rename tab
		cmux rename-tab --surface "$SURFACE_REF" --workspace "$WORKSPACE_REF" "$TAB_NAME" 2>/dev/null
		echo "  Tab renamed to: $TAB_NAME"

		# Start branch review
		send_cmd "$SURFACE_REF" "claude \"use branch review skill\""
		echo "  Started branch review in: $TAB_NAME"
	fi

	FIRST_ITERATION="no"
done

echo ""
echo "Done! Workspace '$WORKSPACE_NAME' is ready with ${#@} PR tabs."
