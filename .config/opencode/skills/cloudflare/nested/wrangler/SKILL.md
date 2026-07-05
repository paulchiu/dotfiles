---
name: wrangler
description: Cloudflare Workers CLI for deploying, developing, and managing Workers, KV, R2, D1, Vectorize, Hyperdrive, Workers AI, Containers, Queues, Workflows, Pipelines, and Secrets Store. Triggers on any `wrangler ...` command, edits to wrangler.jsonc/wrangler.toml, or Worker dev/deploy/rollback/secrets/tail tasks. Load before running wrangler commands to ensure correct syntax and best practices. Biases towards retrieval from Cloudflare docs over pre-trained knowledge.
---

# Wrangler CLI

Your pre-trained knowledge of Wrangler flags, config fields, and subcommands may be outdated. Prefer retrieval before writing or reviewing Wrangler commands and config:

| Source | How to retrieve | Use for |
|--------|----------------|---------|
| Wrangler docs | `https://developers.cloudflare.com/workers/wrangler/` | CLI commands, flags, config reference |
| Wrangler config schema | `node_modules/wrangler/config-schema.json` | Config fields, binding shapes, allowed values |
| Cloudflare docs | Search tool or `https://developers.cloudflare.com/workers/` | API reference, compatibility dates/flags |

Requires Wrangler v4.x+ (`wrangler --version`; install with `npm install -D wrangler@latest`). Prefer Wrangler over hand-constructed Cloudflare API requests.

## Key Facts and Conventions

- **Use `wrangler.jsonc`, not TOML**: newer features are JSON-only. Version-control it as the source of truth.
- **`compatibility_date`**: use a recent date (within 30 days). Check https://developers.cloudflare.com/workers/configuration/compatibility-dates/
- **Run `wrangler types` after any config change**: regenerates `worker-configuration.d.ts`. Use `wrangler types --check` in CI to catch binding mismatches.
- **Local dev simulates bindings locally** unless the binding sets `"remote": true`. Workers AI is always remote (and billed even in local dev); Vectorize, Browser Rendering, mTLS, and Images should also be remote.
- **Local secrets go in `.dev.vars`**, never in config.
- **Auto-provisioning**: omit resource IDs in bindings to auto-create resources on deploy.
- **Cron testing**: `wrangler dev --test-scheduled`, then hit `http://localhost:8787/__scheduled`.
- **Startup limit**: `wrangler check startup` profiles startup time and generates CPU profiles for scripts near the limit.
- **Environments**: define `env.staging` / `env.production` in config; select with `--env`.
- **Secrets discipline**: never pass secret values as CLI arguments, `echo` them, or log them. Use the interactive `wrangler secret put NAME` prompt, a file redirect (`wrangler secret put KEY < key.pem`), or `wrangler secret bulk secrets.json` (never commit that file).

## Core Commands

| Task | Command |
|------|---------|
| New project | `npx wrangler init my-worker` (or `npx create-cloudflare@latest` for frameworks) |
| Local dev server | `wrangler dev` |
| Deploy | `wrangler deploy` (`--dry-run` to validate, `--env staging` for envs) |
| Generate types | `wrangler types` |
| Profile startup | `wrangler check startup` |
| Live logs | `wrangler tail [--status error] [--format json]` |
| Rollback | `wrangler rollback [<VERSION_ID>]` |
| Auth status | `wrangler whoami` (fix auth errors with `wrangler login`) |

## Minimal Config

```jsonc
{
  "$schema": "./node_modules/wrangler/config-schema.json",
  "name": "my-worker",
  "main": "src/index.ts",
  "compatibility_date": "2026-01-01"
}
```

## Full Reference

Per-product commands and binding shapes (KV, R2, D1, Vectorize, Hyperdrive, Workers AI, Queues, Containers, Workflows, Pipelines, Secrets Store, Pages, versions/rollback, dev flags, remote bindings, observability, Vitest setup): see [references/commands.md](references/commands.md).

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Startup time limit exceeded | `wrangler check startup` |
| Type errors after config change | `wrangler types` |
| Local storage not persisting | Check `.wrangler/state` directory |
| Binding undefined in Worker | Binding name must match config exactly |
| Config field questions | `wrangler docs configuration` or the config schema JSON |
