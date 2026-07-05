# Wrangler Command and Binding Reference

Per-product commands and `wrangler.jsonc` binding shapes. Verify flags against the retrieval sources in SKILL.md before use; this file is a syntax aid, not a substitute for the config schema.

## Full Config with Bindings

```jsonc
{
  "$schema": "./node_modules/wrangler/config-schema.json",
  "name": "my-worker",
  "main": "src/index.ts",
  "compatibility_date": "2026-01-01",
  "compatibility_flags": ["nodejs_compat"],

  // Environment variables
  "vars": {
    "ENVIRONMENT": "production"
  },

  // KV Namespace
  "kv_namespaces": [
    { "binding": "KV", "id": "<KV_NAMESPACE_ID>" }
  ],

  // R2 Bucket
  "r2_buckets": [
    { "binding": "BUCKET", "bucket_name": "my-bucket" }
  ],

  // D1 Database
  "d1_databases": [
    { "binding": "DB", "database_name": "my-db", "database_id": "<DB_ID>" }
  ],

  // Workers AI (always remote)
  "ai": { "binding": "AI" },

  // Vectorize
  "vectorize": [
    { "binding": "VECTOR_INDEX", "index_name": "my-index" }
  ],

  // Hyperdrive
  "hyperdrive": [
    { "binding": "HYPERDRIVE", "id": "<HYPERDRIVE_ID>" }
  ],

  // Durable Objects
  "durable_objects": {
    "bindings": [
      { "name": "COUNTER", "class_name": "Counter" }
    ]
  },

  // Cron triggers
  "triggers": {
    "crons": ["0 * * * *"]
  },

  // Environments
  "env": {
    "staging": {
      "name": "my-worker-staging",
      "vars": { "ENVIRONMENT": "staging" }
    }
  }
}
```

## Types

```bash
wrangler types                  # Generate worker-configuration.d.ts
wrangler types ./src/env.d.ts   # Custom output path
wrangler types --check          # CI: verify types are up to date
```

## Dev Server Flags

```bash
wrangler dev                    # Local mode (default): local storage simulation
wrangler dev --env staging      # Specific environment
wrangler dev --local            # Force local-only (disable remote bindings)
wrangler dev --remote           # Run on Cloudflare edge (legacy)
wrangler dev --port 8787        # Custom port
wrangler dev --live-reload      # Live reload for HTML changes
wrangler dev --test-scheduled   # Enable cron testing; trigger via http://localhost:8787/__scheduled
```

### Remote Bindings for Local Dev

`remote: true` on a binding connects to the real resource while running locally:

```jsonc
{
  "r2_buckets": [
    { "binding": "BUCKET", "bucket_name": "my-bucket", "remote": true }
  ],
  "ai": { "binding": "AI", "remote": true },
  "vectorize": [
    { "binding": "INDEX", "index_name": "my-index", "remote": true }
  ]
}
```

Recommended remote bindings: AI (required), Vectorize, Browser Rendering, mTLS, Images.

## Deploy

```bash
wrangler deploy                 # Deploy to production
wrangler deploy --env staging   # Deploy specific environment
wrangler deploy --dry-run       # Validate without deploying
wrangler deploy --keep-vars     # Keep dashboard-set variables
wrangler deploy --minify
```

## Worker Secrets

Never pass secret values as command arguments or via `echo`. Use the interactive prompt, a file redirect, or `secret bulk`.

```bash
wrangler secret put API_KEY                          # Interactive prompt (preferred)
wrangler secret put PRIVATE_KEY < path/to/key.pem    # From file (PEM keys, CI)
wrangler secret list
wrangler secret delete API_KEY
wrangler secret bulk secrets.json                    # Bulk from JSON (never commit this file)
```

## Versions and Rollback

```bash
wrangler versions list
wrangler versions view <VERSION_ID>
wrangler rollback                 # To previous version
wrangler rollback <VERSION_ID>
```

## KV

```bash
wrangler kv namespace create MY_KV
wrangler kv namespace list
wrangler kv namespace delete --namespace-id <ID>

wrangler kv key put --namespace-id <ID> "key" "value"
wrangler kv key put --namespace-id <ID> "key" "value" --expiration-ttl 3600
wrangler kv key get --namespace-id <ID> "key"
wrangler kv key list --namespace-id <ID>
wrangler kv key delete --namespace-id <ID> "key"
wrangler kv bulk put --namespace-id <ID> data.json
```

Binding: `"kv_namespaces": [{ "binding": "CACHE", "id": "<NAMESPACE_ID>" }]`

## R2

```bash
wrangler r2 bucket create my-bucket [--location wnam]
wrangler r2 bucket list
wrangler r2 bucket info my-bucket
wrangler r2 bucket delete my-bucket

wrangler r2 object put my-bucket/path/file.txt --file ./local-file.txt
wrangler r2 object get my-bucket/path/file.txt
wrangler r2 object delete my-bucket/path/file.txt
```

Binding: `"r2_buckets": [{ "binding": "ASSETS", "bucket_name": "my-bucket" }]`

## D1

```bash
wrangler d1 create my-database [--location wnam]
wrangler d1 list
wrangler d1 info my-database
wrangler d1 delete my-database

# Execute SQL: --remote or --local is required to disambiguate
wrangler d1 execute my-database --remote --command "SELECT * FROM users"
wrangler d1 execute my-database --remote --file ./schema.sql
wrangler d1 execute my-database --local --command "SELECT * FROM users"

# Migrations
wrangler d1 migrations create my-database create_users_table
wrangler d1 migrations list my-database --local
wrangler d1 migrations apply my-database --local
wrangler d1 migrations apply my-database --remote

# Export/backup
wrangler d1 export my-database --remote --output backup.sql
wrangler d1 export my-database --remote --output schema.sql --no-data
```

Binding:

```jsonc
{
  "d1_databases": [
    {
      "binding": "DB",
      "database_name": "my-database",
      "database_id": "<DATABASE_ID>",
      "migrations_dir": "./migrations"
    }
  ]
}
```

## Vectorize

```bash
wrangler vectorize create my-index --dimensions 768 --metric cosine
wrangler vectorize create my-index --preset @cf/baai/bge-base-en-v1.5   # auto-configures dims/metric
wrangler vectorize list
wrangler vectorize get my-index
wrangler vectorize delete my-index

wrangler vectorize insert my-index --file vectors.ndjson
wrangler vectorize query my-index --vector "[0.1, 0.2, ...]" --top-k 10
```

Binding: `"vectorize": [{ "binding": "SEARCH_INDEX", "index_name": "my-index" }]`

## Hyperdrive

Requires `"compatibility_flags": ["nodejs_compat"]`.

```bash
wrangler hyperdrive create my-hyperdrive \
  --origin-host db.example.com \
  --origin-port 5432 \
  --database my-database \
  --origin-user db-user \
  --origin-password "$DB_PASSWORD"

# Or from a connection string in an env var
wrangler hyperdrive create my-hyperdrive \
  --connection-string "$HYPERDRIVE_CONNECTION_STRING"

wrangler hyperdrive list
wrangler hyperdrive get <HYPERDRIVE_ID>
wrangler hyperdrive update <HYPERDRIVE_ID> --origin-password "$DB_PASSWORD"
wrangler hyperdrive delete <HYPERDRIVE_ID>
```

Binding: `"hyperdrive": [{ "binding": "HYPERDRIVE", "id": "<HYPERDRIVE_ID>" }]`

## Workers AI

```bash
wrangler ai models          # List available models
wrangler ai finetune list
```

Binding: `"ai": { "binding": "AI" }`

Workers AI always runs remotely and incurs usage charges even in local dev.

## Queues

```bash
wrangler queues create my-queue
wrangler queues list
wrangler queues delete my-queue
wrangler queues consumer add my-queue my-worker
wrangler queues consumer remove my-queue my-worker
```

Binding:

```jsonc
{
  "queues": {
    "producers": [
      { "binding": "MY_QUEUE", "queue": "my-queue" }
    ],
    "consumers": [
      { "queue": "my-queue", "max_batch_size": 10, "max_batch_timeout": 30 }
    ]
  }
}
```

## Containers

```bash
wrangler containers build -t my-app:latest .
wrangler containers build -t my-app:latest . --push   # build and push
wrangler containers push my-app:latest                # push existing image

wrangler containers list
wrangler containers info <CONTAINER_ID>
wrangler containers delete <CONTAINER_ID>

wrangler containers images list
wrangler containers images delete my-app:latest
```

External registries (never hardcode credentials; use env vars):

```bash
wrangler containers registries list
wrangler containers registries configure <DOMAIN> --aws-access-key-id "$AWS_ACCESS_KEY_ID"
wrangler containers registries configure <DOMAIN> --dockerhub-username "$DOCKERHUB_USERNAME"
wrangler containers registries delete <DOMAIN>
```

## Workflows

```bash
wrangler workflows list
wrangler workflows describe my-workflow
wrangler workflows trigger my-workflow [--params '{"key": "value"}']
wrangler workflows delete my-workflow

wrangler workflows instances list my-workflow
wrangler workflows instances describe my-workflow <INSTANCE_ID>
wrangler workflows instances terminate my-workflow <INSTANCE_ID>
```

Binding:

```jsonc
{
  "workflows": [
    { "binding": "MY_WORKFLOW", "name": "my-workflow", "class_name": "MyWorkflow" }
  ]
}
```

## Pipelines

```bash
wrangler pipelines create my-pipeline --r2 my-bucket
wrangler pipelines list
wrangler pipelines show my-pipeline
wrangler pipelines update my-pipeline --batch-max-mb 100
wrangler pipelines delete my-pipeline
```

Binding: `"pipelines": [{ "binding": "MY_PIPELINE", "pipeline": "my-pipeline" }]`

## Secrets Store

```bash
wrangler secrets-store store create my-store
wrangler secrets-store store list
wrangler secrets-store store delete <STORE_ID>

wrangler secrets-store secret put <STORE_ID> my-secret
wrangler secrets-store secret list <STORE_ID>
wrangler secrets-store secret get <STORE_ID> my-secret
wrangler secrets-store secret delete <STORE_ID> my-secret
```

Binding:

```jsonc
{
  "secrets_store_secrets": [
    { "binding": "MY_SECRET", "store_id": "<STORE_ID>", "secret_name": "my-secret" }
  ]
}
```

## Pages

```bash
wrangler pages project create my-site
wrangler pages deploy ./dist [--branch main]
wrangler pages deployment list --project-name my-site
```

## Observability

```bash
wrangler tail [my-worker]
wrangler tail --status error
wrangler tail --search "error"
wrangler tail --format json
```

Config:

```jsonc
{
  "observability": { "enabled": true, "head_sampling_rate": 1 }
}
```

## Testing with Vitest

```bash
npm install -D @cloudflare/vitest-pool-workers vitest
```

`vitest.config.ts`:

```typescript
import { defineWorkersConfig } from "@cloudflare/vitest-pool-workers/config";

export default defineWorkersConfig({
  test: {
    poolOptions: {
      workers: {
        wrangler: { configPath: "./wrangler.jsonc" },
      },
    },
  },
});
```
