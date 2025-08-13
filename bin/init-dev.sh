#!/bin/zsh

# Define the list of directories and branches
REPO_BRANCH=(
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
  "manage-api:main"
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

# Use xargs to run the separate script in parallel
export DEV_HOME="${DEV_HOME:-/Users/paul/dev}"
export BIN_DIR=${0:a:h}
export PROCESSES=10
printf "%s\n" "${REPO_BRANCH[@]}" | xargs -n 1 -P $PROCESSES -I {} $BIN_DIR/process_item.sh {}
