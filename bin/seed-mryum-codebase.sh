#!/usr/bin/env bash

set -euo pipefail

TARGET_DIR="${1:-$HOME/mryum-codebase}"
PROCESSES="${PROCESSES:-8}"

REPO_BRANCHES=(
  "bill-api:main"
  "bill-db-schema:main"
  "bill-worker:main"
  "cloudflare-workers:main"
  "crew:main"
  "crew-contract:main"
  "crew-db-schema:main"
  "crew-frontend:main"
  "crew-infra:main"
  "data-analytics:main"
  "db-tasks:main"
  "guest-gateway:main"
  "integration-config:main"
  "loyalty:main"
  "loyalty-api:main"
  "loyalty-contract:main"
  "loyalty-db-schema:main"
  "loyalty-infra:main"
  "loyalty-integrations:main"
  "loyalty-worker:main"
  "manage:main"
  "manage-frontend:main"
  "menu-api:main"
  "menu-sync:main"
  "mr-yum-db-schema:main"
  "mr-yum:master"
  "order-api:main"
  "order-db-schema:main"
  "order-worker:main"
  "partner-db-schema:main"
  "payment-api:main"
  "payment-db-schema:main"
  "payment-infra:main"
  "payment-worker:main"
  "payout-api:main"
  "payout-db-schema:main"
  "payout-infra:main"
  "payout-worker:main"
  "pos-integrations:main"
  "serve-api:main"
  "serve-frontend:main"
  "venue-api:main"
)

clone_or_update_repo() {
  local item="$1"
  local repo="${item%%:*}"
  local branch="${item##*:}"
  local repo_dir="${TARGET_DIR}/${repo}"
  local repo_url="git@github.com:mr-yum/${repo}.git"

  if [[ ! -d "${repo_dir}/.git" ]]; then
    printf "[%s] cloning into %s\n" "${repo}" "${repo_dir}"
    git clone "${repo_url}" "${repo_dir}"
  else
    printf "[%s] already exists, fetching latest refs\n" "${repo}"
  fi

  git -C "${repo_dir}" fetch --all --prune
  git -C "${repo_dir}" checkout "${branch}"
  git -C "${repo_dir}" pull --ff-only origin "${branch}"
}

export TARGET_DIR
export -f clone_or_update_repo

mkdir -p "${TARGET_DIR}"

printf "Seeding %s with %s repos\n" "${TARGET_DIR}" "${#REPO_BRANCHES[@]}"
printf "%s\n" "${REPO_BRANCHES[@]}" | xargs -n 1 -P "${PROCESSES}" -I {} bash -lc 'clone_or_update_repo "$@"' _ {}

printf "Done. Repos are available in %s\n" "${TARGET_DIR}"
