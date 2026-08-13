#!/usr/bin/env bash

# Combined pull request script
# Usage:
#   ./aipr write [args]       - Write PR using aichat from git diff input
#   ./aipr create_only [args] - Create PR using GitHub CLI from formatted input
#   ./aipr create [args]      - Write PR from git diff then create it (pipeline)
#   ./aipr [args]             - Default to write mode

set -euo pipefail

write_pull_request() {
    local template_file=".github/pull_request_template.md"
    if [[ -f "$template_file" ]]; then
        aichat --role pr-writer -f "$template_file" "$@"
    else
        aichat --role pr-writer "$@"
    fi
}

create_pull_request() {
    local debug=false
    local args=()

    while [[ $# -gt 0 ]]; do
        case $1 in
            --debug)
                debug=true
                shift
                ;;
            *)
                args+=("$1")
                shift
                ;;
        esac
    done

    if [ "$debug" = false ] && ! command -v gh >/dev/null 2>&1; then
        echo "Error: GitHub CLI not found. Install with: brew install gh" >&2
        return 1
    fi

    local input=$(cat)

    if ! echo "$input" | grep -q "^----$"; then
        echo "Error: Invalid format. Expected: [TITLE]\\n----\\n[DESCRIPTION]" >&2
        return 1
    fi

    local title=$(echo "$input" | \sed '/^----$/,$d' | tr -d '\n' | \sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    local description=$(echo "$input" | \sed -n '/^----$/,$p' | \sed '1d')

    if [[ -z "$title" || -z "$description" ]]; then
        echo "Error: Both title and description are required" >&2
        return 1
    fi

    if [ "$debug" = true ]; then
        echo "Title: $title"
        echo "Description: $description"
        if [[ ${#args[@]} -gt 0 ]]; then
            echo "Args: ${args[*]}"
        else
            echo "Args: (none)"
        fi
    else
        if [[ ${#args[@]} -gt 0 ]]; then
            gh pr create --web --title "$title" --body "$description" "${args[@]}"
        else
            gh pr create --web --title "$title" --body "$description"
        fi
    fi
}

write_and_create_pull_request() {
    local temp_file=$(mktemp)
    trap "rm -f $temp_file" EXIT

    # Write PR content to temp file
    write_pull_request "$@" > "$temp_file"

    # Create PR from temp file
    create_pull_request "$@" < "$temp_file"
}

create_from_diff() {
    local debug=false
    local write_args=()
    local create_args=()

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --debug)
                debug=true
                create_args+=("$1")
                shift
                ;;
            *)
                write_args+=("$1")
                create_args+=("$1")
                shift
                ;;
        esac
    done

    # First write the PR from the git diff input, then create it
    local temp_file=$(mktemp)
    local formatted_file=$(mktemp)
    trap "rm -f $temp_file $formatted_file" EXIT

    # Write PR content to temp file from stdin (git diff)
    if [[ ${#write_args[@]} -gt 0 ]]; then
        write_pull_request "${write_args[@]}" > "$temp_file"
    else
        write_pull_request > "$temp_file"
    fi

    # Check if the output is already in the correct format
    if grep -q "^----$" "$temp_file"; then
        # Already in correct format, use as-is
        if [[ ${#create_args[@]} -gt 0 ]]; then
            create_pull_request "${create_args[@]}" < "$temp_file"
        else
            create_pull_request < "$temp_file"
        fi
    else
        # Not in correct format, need to extract title and format properly
        local content=$(cat "$temp_file")
        local title=""

        # Try to extract a title from the first line or create a generic one
        if [[ "$content" =~ ^([^.!?]*[.!?]) ]]; then
            # Use first sentence as title, but limit length
            title=$(echo "$content" | head -1 | cut -c1-72)
            if [[ ${#title} -eq 72 && ! "$title" =~ [.!?]$ ]]; then
                title="${title}..."
            fi
        else
            # Use first line as title, but limit length
            title=$(echo "$content" | head -1 | cut -c1-72)
            if [[ ${#title} -eq 72 ]]; then
                title="${title}..."
            fi
        fi

        # If no reasonable title found, use generic one
        if [[ -z "$title" || ${#title} -lt 10 ]]; then
            title="Update code based on changes"
        fi

        # Create properly formatted output        echo "$title" > "$formatted_file"
        echo "----" >> "$formatted_file"
        echo "$content" >> "$formatted_file"

        if [[ ${#create_args[@]} -gt 0 ]]; then
            create_pull_request "${create_args[@]}" < "$formatted_file"
        else
            create_pull_request < "$formatted_file"
        fi
    fi
}

main() {
    case "${1:-write}" in
        write)
            shift
            write_pull_request "$@"
            ;;
        create_only)
            shift
            create_pull_request "$@"
            ;;
        create)
            shift
            create_from_diff "$@"
            ;;
        *)
            write_pull_request "$@"
            ;;
    esac
}

main "$@"
