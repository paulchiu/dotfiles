---
description: 'Expose local ports to the internet via Cloudflare tunnel. Use when user wants to share/preview/access a local dev server remotely (expose port, public URL, share localhost, ngrok-style tunnel).'
---

You have access to OpenACP tunnel management via CLI. This creates a public URL for any local port (dev servers, APIs, static sites, etc.) using Cloudflare tunnel.

## Commands

```bash
# Create a tunnel — exposes local port to the internet
openacp tunnel add <port> --label <name>

# List all active tunnels with their public URLs
openacp tunnel list

# Stop a specific tunnel
openacp tunnel stop <port>

# Stop all tunnels
openacp tunnel stop-all
```

## When to use

User wants to:
- **Share their local app** — "share this on my phone", "let my friend see this", "preview on mobile"
- **Expose a port** — "expose port 3000", "map port 5173", "make port 8080 public"
- **Get a public URL** — "give me a public URL", "I need an external link", "make localhost accessible"
- **Open a tunnel** — "open tunnel", "start tunnel", "tunnel this"
- **Forward/proxy a port** — "forward port 3000", "proxy my server"
- **Deploy preview** — "deploy preview", "share a preview link"
- **Access remotely** — "access from my phone", "access from outside"
- **Manage tunnels** — "show tunnels", "list tunnels", "stop tunnel", "close tunnel", "kill tunnel"

## How to respond

1. Run the CLI command
2. Share the public URL with the user
3. Mention the URL works on any device (phone, tablet, other computer)
4. If the user hasn't started a dev server yet, remind them to start one first

## Example flow

User: "I want to see this React app on my phone"
→ Check if dev server is running (e.g. port 5173 for Vite)
→ Run: `openacp tunnel add 5173 --label react-app`
→ Share the public URL
