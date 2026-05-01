#!/usr/bin/env zsh
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  cleanup_sandbox.zsh --repo PATH [--cutoff YYYY-MM-DD] [--dry-run|--apply]

Defaults:
  --cutoff is yesterday in local time.
  --dry-run is used unless --apply is passed.

This script:
  - Renames visible, non-dated, top-level document files with their created date.
  - Moves root files/directories dated on or before the cutoff into archive/yyyy-mm/yyyy-mm-dd/.
  - Moves direct archive children named "yyyy-mm-dd" or "yyyy-mm-dd ..." into matching month/day folders.
  - Uses git mv for tracked paths and mv for untracked paths.
EOF
}

repo=""
cutoff=""
mode="dry-run"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      repo="${2:-}"
      shift 2
      ;;
    --cutoff)
      cutoff="${2:-}"
      shift 2
      ;;
    --dry-run)
      mode="dry-run"
      shift
      ;;
    --apply)
      mode="apply"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$repo" ]]; then
  repo="$PWD"
fi

cd "$repo"
git rev-parse --show-toplevel >/dev/null

if [[ -z "$cutoff" ]]; then
  if cutoff="$(date -v-1d +%F 2>/dev/null)"; then
    :
  else
    cutoff="$(date -d 'yesterday' +%F)"
  fi
fi

if [[ ! "$cutoff" =~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' ]]; then
  echo "Invalid cutoff date: $cutoff" >&2
  exit 2
fi

is_document_file() {
  local entry_path="$1"
  case "${entry_path:e:l}" in
    md|txt|csv|json|mjs|js|sql|png) return 0 ;;
    *) return 1 ;;
  esac
}

is_workspace_config_file() {
  local entry_path="$1"
  case "$entry_path" in
    AGENTS.md|CLAUDE.md) return 0 ;;
    *) return 1 ;;
  esac
}

created_date() {
  local entry_path="$1"
  local value=""

  if value="$(stat -f '%SB' -t '%Y-%m-%d' "$entry_path" 2>/dev/null)"; then
    if [[ "$value" =~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' ]]; then
      print -r -- "$value"
      return 0
    fi
  fi

  echo "Could not determine created-at date for: $entry_path" >&2
  return 1
}

trim_title() {
  sed -E \
    -e 's/[[:space:]]+/ /g' \
    -e 's#[/:]+# #g' \
    -e 's/^[[:space:]]+//' \
    -e 's/[[:space:]]+$//' \
    -e 's/[.]+$//'
}

title_from_markdown() {
  local entry_path="$1"
  local stem="${2}"

  awk -v stem="$stem" '
    function trim(s) {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", s)
      return s
    }
    /^#{1,3}[[:space:]]+/ {
      title = $0
      sub(/^#{1,3}[[:space:]]+/, "", title)
      title = trim(title)
      if (title != "" && title != stem && title != stem ".md") {
        print title
        exit
      }
    }
  ' "$entry_path" | head -n 1 | trim_title
}

title_from_name() {
  local stem="$1"
  print -r -- "$stem" | sed -E 's/[-_]+/ /g' | trim_title
}

derived_title() {
  local entry_path="$1"
  local stem="${entry_path:t:r}"
  local title=""

  if [[ "${entry_path:e:l}" == "md" ]]; then
    title="$(title_from_markdown "$entry_path" "$stem")"
  fi

  if [[ -z "$title" ]]; then
    title="$(title_from_name "$stem")"
  fi

  if [[ -z "$title" ]]; then
    echo "Could not derive title for: $entry_path" >&2
    return 1
  fi

  print -r -- "$title"
}

is_tracked_path() {
  local entry_path="$1"
  if [[ -d "$entry_path" ]]; then
    [[ -n "$(git ls-files -- "$entry_path")" ]]
  else
    git ls-files --error-unmatch -- "$entry_path" >/dev/null 2>&1
  fi
}

move_path() {
  local src="$1"
  local dst="$2"

  if [[ "$src" == "$dst" ]]; then
    return 0
  fi
  if [[ ! -e "$src" ]]; then
    echo "Missing source: $src" >&2
    return 1
  fi
  if [[ -e "$dst" ]]; then
    echo "Destination already exists: $dst" >&2
    return 1
  fi

  print -r -- "$src -> $dst"

  if [[ "$mode" == "dry-run" ]]; then
    return 0
  fi

  mkdir -p "${dst:h}"

  if is_tracked_path "$src"; then
    git mv "$src" "$dst"
  else
    mv "$src" "$dst"
  fi
}

date_prefix_for_name() {
  local name="$1"
  if [[ "$name" =~ '^([0-9]{4}-[0-9]{2}-[0-9]{2})[[:space:]].+' ]]; then
    print -r -- "${match[1]}"
    return 0
  fi
  return 1
}

archive_bucket_for_date() {
  local date_part="$1"
  local month_part="${date_part%-??}"
  print -r -- "archive/$month_part/$date_part"
}

print -r -- "repo: $repo"
print -r -- "cutoff: $cutoff"
print -r -- "mode: $mode"

for entry in *(N); do
  [[ "$entry" == "archive" ]] && continue
  [[ "$entry" == .* ]] && continue
  [[ -f "$entry" ]] || continue
  is_workspace_config_file "$entry" && continue
  is_document_file "$entry" || continue

  if date_prefix_for_name "$entry" >/dev/null; then
    continue
  fi

  date_part="$(created_date "$entry")"
  title_part="$(derived_title "$entry")"
  ext="${entry:e}"
  dst="${date_part} ${title_part}.${ext}"
  move_path "$entry" "$dst"
done

if [[ "$mode" == "apply" ]]; then
  mkdir -p archive
fi

for entry in *(N); do
  [[ "$entry" == "archive" ]] && continue
  [[ "$entry" == .* ]] && continue

  if date_part="$(date_prefix_for_name "$entry")"; then
    if [[ "$date_part" < "$cutoff" || "$date_part" == "$cutoff" ]]; then
      move_path "$entry" "$(archive_bucket_for_date "$date_part")/$entry"
    fi
  fi
done

for entry in archive/*(N); do
  base="${entry:t}"

  if [[ "$base" =~ '^[0-9]{4}-[0-9]{2}$' ]]; then
    continue
  fi

  if [[ "$base" =~ '^([0-9]{4}-[0-9]{2}-[0-9]{2})$' ]]; then
    move_path "$entry" "$(archive_bucket_for_date "$base")"
    continue
  fi

  if date_part="$(date_prefix_for_name "$base")"; then
    move_path "$entry" "$(archive_bucket_for_date "$date_part")/$base"
  fi
done

for month_dir in archive/[0-9][0-9][0-9][0-9]-[0-9][0-9](N/); do
  for entry in "$month_dir"/*(N); do
    base="${entry:t}"

    if [[ "$base" =~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' ]]; then
      continue
    fi

    if date_part="$(date_prefix_for_name "$base")"; then
      move_path "$entry" "$(archive_bucket_for_date "$date_part")/$base"
    fi
  done
done

print -r -- "done"
