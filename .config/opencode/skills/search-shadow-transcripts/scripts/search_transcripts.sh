#!/usr/bin/env bash
# Search Shadow.app transcripts from local SQLite database
# Usage: ./search_transcripts.sh [search_term] [options]

DB_PATH="$HOME/Library/Application Support/com.taperlabs.shadow/shadow.db"

# Show usage if no arguments provided
if [ $# -eq 0 ]; then
	echo "Usage: $0 <search_term> [options]"
	echo ""
	echo "Options:"
	echo "  --recent          Show only transcripts from today"
	echo "  --conversation    Show conversation ID for each match"
	echo "  --count           Count matches only"
	echo "  --raw             Output raw results (no formatting)"
	echo ""
	echo "Examples:"
	echo "  $0 'meeting notes'"
	echo "  $0 'project update' --recent"
	echo "  $0 'action items' --conversation"
	exit 1
fi

SEARCH_TERM="$1"
shift

# Parse options
SHOW_CONVERSATION=false
COUNT_ONLY=false
RAW_OUTPUT=false
RECENT_ONLY=false

while [ $# -gt 0 ]; do
	case "$1" in
	--conversation)
		SHOW_CONVERSATION=true
		shift
		;;
	--count)
		COUNT_ONLY=true
		shift
		;;
	--raw)
		RAW_OUTPUT=true
		shift
		;;
	--recent)
		RECENT_ONLY=true
		shift
		;;
	*)
		echo "Unknown option: $1"
		exit 1
		;;
	esac
done

# Check if database exists
if [ ! -f "$DB_PATH" ]; then
	echo "Error: Shadow database not found at $DB_PATH"
	exit 1
fi

# Build query
if [ "$COUNT_ONLY" = true ]; then
	QUERY="SELECT COUNT(*) FROM SHADOW_TRANSCRIPT WHERE transContent LIKE '%$SEARCH_TERM%';"
elif [ "$SHOW_CONVERSATION" = true ]; then
	QUERY="SELECT t.convIdx, c.convTitle, c.convStartedAt, t.transStartedAt, t.transContent 
		FROM SHADOW_TRANSCRIPT t 
		JOIN SHADOW_CONVERSATION c ON t.convIdx = c.convIdx 
		WHERE t.transContent LIKE '%$SEARCH_TERM%' 
		ORDER BY t.transStartedAt DESC;"
else
	QUERY="SELECT t.transContent, c.convTitle, c.convStartedAt 
		FROM SHADOW_TRANSCRIPT t 
		JOIN SHADOW_CONVERSATION c ON t.convIdx = c.convIdx 
		WHERE t.transContent LIKE '%$SEARCH_TERM%' 
		ORDER BY t.transStartedAt DESC;"
fi

# Execute query
if [ "$RAW_OUTPUT" = true ]; then
	sqlite3 "$DB_PATH" "$QUERY"
else
	echo "Searching Shadow transcripts for: '$SEARCH_TERM'"
	echo ""

	if [ "$SHOW_CONVERSATION" = true ]; then
		sqlite3 "$DB_PATH" "$QUERY" | while IFS='|' read -r convId convTitle convStart transTime content; do
			# Format conversation start time
			if [ -n "$convStart" ] && [ "$convStart" != "" ]; then
				conv_date=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${convStart%%.*}" "+%Y-%m-%d %H:%M %Z" 2>/dev/null || echo "$convStart")
			else
				conv_date="Unknown"
			fi
			echo "[$conv_date] $convTitle (Conversation #$convId):"
			echo "  $content"
			echo ""
		done
	else
		sqlite3 "$DB_PATH" "$QUERY" | while IFS='|' read -r content convTitle convStart; do
			if [ -n "$convStart" ] && [ "$convStart" != "" ]; then
				conv_date=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${convStart%%.*}" "+%Y-%m-%d %H:%M %Z" 2>/dev/null || echo "$convStart")
			else
				conv_date="Unknown"
			fi
			echo "[$conv_date] $convTitle:"
			echo "  $content"
			echo ""
		done
	fi
fi
