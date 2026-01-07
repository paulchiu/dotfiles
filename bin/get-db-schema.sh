#!/bin/bash

set -euo pipefail

SOURCE="/Users/paul/dev/manage/node_modules/@mr-yum/mr-yum-db-schema/schema.sql"

usage() {
  echo "Usage: $0 <destination_dir> [output_filename]"
  echo "Example: $0 ~/Downloads schema.sql"
}

if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

DEST_DIR="$1"
OUTPUT_NAME="${2:-schema.sql}"

if [[ ! -f "$SOURCE" ]]; then
  echo "Error: Schema not found at: $SOURCE" >&2
  echo "Tip: Ensure manage-api dependencies are installed and path is correct." >&2
  exit 1
fi

mkdir -p "$DEST_DIR"
DEST_PATH="$DEST_DIR/$OUTPUT_NAME"

cp "$SOURCE" "$DEST_PATH"

echo "Copied schema to: $DEST_PATH"

