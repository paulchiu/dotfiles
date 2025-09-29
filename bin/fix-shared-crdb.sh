#!/usr/bin/env bash
set -euo pipefail

if ! command -v docker >/dev/null 2>&1; then
  echo "docker command not found" >&2
  exit 1
fi

echo "Checking for shared-crdb container..."
container_listing=$(docker ps -a --filter name=shared-crdb)

# Always show what docker reports so the user can review it
printf '%s\n' "$container_listing"

# Skip header line (first line) when checking for matches
if ! printf '%s\n' "$container_listing" | tail -n +2 | grep -q 'shared-crdb'; then
  echo "No container named shared-crdb found."
  exit 0
fi

echo
read -r -p "Remove container shared-crdb? [y/N]: " response
case "${response:-}" in
  [yY]|[yY][eE][sS])
    echo "Removing shared-crdb..."
    if docker rm shared-crdb; then
      echo "Confirming removal..."
      post_listing=$(docker ps -a --filter name=shared-crdb)
      printf '%s\n' "$post_listing"
      if printf '%s\n' "$post_listing" | tail -n +2 | grep -q 'shared-crdb'; then
        echo "shared-crdb still present. Removal may have failed." >&2
        exit 1
      else
        echo "shared-crdb removal confirmed."
      fi
    else
      echo "Failed to remove shared-crdb." >&2
      exit 1
    fi
    ;;
  *)
    echo "Removal cancelled."
    ;;
esac
