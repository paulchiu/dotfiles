---
name: cloudflare-email-service
description: Send and receive transactional emails with Cloudflare Email Service (Email Sending + Email Routing). Use when building email sending (Workers binding or REST API), email routing, Agents SDK email handling, or integrating email into any app (Workers, Node.js, Python, Go, etc.). Also use for email deliverability, SPF/DKIM/DMARC, wrangler email setup, MCP email tools, or when a coding agent needs to send emails. Even for simple requests like "add email to my Worker", this skill has critical config details.
---

# Cloudflare Email Service

Send transactional emails and route incoming emails within the Cloudflare platform. The product launched in 2025 and is evolving rapidly, so pre-trained knowledge is likely stale. **Prefer retrieval** from the sources below, and if this skill disagrees with them, trust the source.

## Retrieval Sources

| Source | How to retrieve | Use for |
|--------|----------------|---------|
| Cloudflare docs | `cloudflare-docs` search tool or URL `https://developers.cloudflare.com/email-service/` | API reference, limits, pricing, latest features |
| REST API spec | `https://developers.cloudflare.com/api/resources/email_sending` | OpenAPI spec for the Email Sending REST API |
| Workers types | `https://www.npmjs.com/package/@cloudflare/workers-types` | Type signatures, binding shapes |
| Agents SDK docs | Fetch `docs/email.md` from `https://github.com/cloudflare/agents/tree/main/docs` | Email handling in Agents SDK |

## FIRST: Check Prerequisites

1. **Domain onboarded?** `npx wrangler email sending list` shows domains with sending enabled. If missing, run `npx wrangler email sending enable userdomain.com` or see [cli-and-mcp.md](references/cli-and-mcp.md).
2. **Binding configured?** Look for `send_email` in `wrangler.jsonc` (Workers).
3. **postal-mime installed?** `npm ls postal-mime` (only needed for receiving/parsing emails).

## What Do You Need?

| I want to... | Path | Reference |
|--------------|------|-----------|
| **Send emails from a Cloudflare Worker** | Workers binding (no API keys needed) | [sending.md](references/sending.md) |
| **Send emails from an AI agent built with [Cloudflare Agents SDK](https://developers.cloudflare.com/agents/)** | `onEmail()` + `replyToEmail()` in Agent class | [sending.md](references/sending.md) |
| **Send emails from an external app or agent** (Node.js, Go, Python, etc.) | REST API with Bearer token | [rest-api.md](references/rest-api.md) |
| **Send emails from a coding agent** (Claude Code, Cursor, Copilot, etc.) | MCP tools, wrangler CLI, or REST API | [cli-and-mcp.md](references/cli-and-mcp.md) |
| **Receive and process incoming emails** (Email Routing) | Workers `email()` handler | [routing.md](references/routing.md) |
| **Set up Email Sending or Email Routing** | `wrangler email sending enable` / `wrangler email routing enable`, or Dashboard | [cli-and-mcp.md](references/cli-and-mcp.md) |
| **Improve deliverability, avoid spam folders** | Authentication, content, compliance | [deliverability.md](references/deliverability.md) |

## Quick Start: Workers Binding

Add the binding to `wrangler.jsonc`, then call `env.EMAIL.send()`. The `from` domain must be onboarded via `npx wrangler email sending enable yourdomain.com`.

```jsonc
// wrangler.jsonc
{ "send_email": [{ "name": "EMAIL" }] }
```

```typescript
const response = await env.EMAIL.send({
  to: "user@example.com",
  from: { email: "welcome@yourdomain.com", name: "My App" },
  subject: "Welcome!",
  html: "<h1>Welcome!</h1>",
  text: "Welcome!",
});
```

The binding is the default choice for Workers (no API keys). If the user specifically wants the REST API from within a Worker, that works too. See [sending.md](references/sending.md) for the full API, batch sends, attachments, custom headers, restricted bindings, and Agents SDK integration.

## Quick Start: REST API

For apps outside Workers, or within Workers if the user explicitly requests it. Key differences from the Workers binding:

- Endpoint: `POST https://api.cloudflare.com/client/v4/accounts/{account_id}/email/sending/send`
- `from` object uses `address` (not `email`): `{ "address": "...", "name": "..." }`
- `replyTo` is `reply_to` (snake_case)
- Response returns `{ delivered: [], permanent_bounces: [], queued: [] }` (not `messageId`)

See [rest-api.md](references/rest-api.md) for curl examples, response format, and error handling.

## Gotchas

- Sending uses a `send_email` **binding**, not an API key. No key setup needed inside Workers.
- The `from` domain must be onboarded to Email Sending before the first send (CLI or Dashboard). Any local part at that domain then works.
- `message.raw` is a single-use stream. Buffer first: `const raw = await new Response(message.raw).arrayBuffer()`.
- `message.forward()` only delivers to verified destination addresses (`wrangler email routing addresses create user@gmail.com` or Dashboard) and fails silently otherwise.
- Field names diverge between surfaces: Workers binding uses `from.email` / `replyTo` / `contentId`; REST API uses `from.address` / `reply_to` / `content_id`.
- Transactional email only. Marketing/bulk sends are not permitted; point users at a dedicated marketing platform.
