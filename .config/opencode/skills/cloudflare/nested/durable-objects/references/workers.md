# Cloudflare Workers Best Practices

High-level guidance for Workers that invoke Durable Objects.

## Wrangler Configuration

### wrangler.jsonc (Recommended)

```jsonc
{
  "$schema": "node_modules/wrangler/config-schema.json",
  "name": "my-worker",
  "main": "src/index.ts",
  "compatibility_date": "2024-12-01",
  "compatibility_flags": ["nodejs_compat"],

  "durable_objects": {
    "bindings": [
      { "name": "CHAT_ROOM", "class_name": "ChatRoom" },
      { "name": "USER_SESSION", "class_name": "UserSession" }
    ]
  },

  "migrations": [
    { "tag": "v1", "new_sqlite_classes": ["ChatRoom", "UserSession"] }
  ],

  // Environment variables
  "vars": {
    "ENVIRONMENT": "production"
  },

  // KV namespaces
  "kv_namespaces": [
    { "binding": "CONFIG", "id": "abc123" }
  ],

  // R2 buckets
  "r2_buckets": [
    { "binding": "UPLOADS", "bucket_name": "my-uploads" }
  ],

  // D1 databases
  "d1_databases": [
    { "binding": "DB", "database_id": "xyz789" }
  ]
}
```

### wrangler.toml (Alternative)

```toml
name = "my-worker"
main = "src/index.ts"
compatibility_date = "2024-12-01"
compatibility_flags = ["nodejs_compat"]

[[durable_objects.bindings]]
name = "CHAT_ROOM"
class_name = "ChatRoom"

[[migrations]]
tag = "v1"
new_sqlite_classes = ["ChatRoom"]

[vars]
ENVIRONMENT = "production"
```

## TypeScript Types

### Environment Interface

```typescript
// src/types.ts
import { ChatRoom } from "./durable-objects/chat-room";
import { UserSession } from "./durable-objects/user-session";

export interface Env {
  // Durable Objects
  CHAT_ROOM: DurableObjectNamespace<ChatRoom>;
  USER_SESSION: DurableObjectNamespace<UserSession>;

  // KV
  CONFIG: KVNamespace;

  // R2
  UPLOADS: R2Bucket;

  // D1
  DB: D1Database;

  // Environment variables
  ENVIRONMENT: string;
  API_KEY: string; // From secrets
}
```

### Export Durable Object Classes

```typescript
// src/index.ts
export { ChatRoom } from "./durable-objects/chat-room";
export { UserSession } from "./durable-objects/user-session";

export default {
  async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    // Worker handler
  },
};
```

## Worker Handler Pattern

```typescript
export default {
  async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    const url = new URL(request.url);

    try {
      // Route to appropriate handler
      if (url.pathname.startsWith("/api/rooms")) {
        return handleRooms(request, env);
      }
      if (url.pathname.startsWith("/api/users")) {
        return handleUsers(request, env);
      }

      return new Response("Not Found", { status: 404 });
    } catch (error) {
      console.error("Request failed:", error);
      return new Response("Internal Server Error", { status: 500 });
    }
  },
};

async function handleRooms(request: Request, env: Env): Promise<Response> {
  const url = new URL(request.url);
  const roomId = url.searchParams.get("room");

  if (!roomId) {
    return Response.json({ error: "Missing room parameter" }, { status: 400 });
  }

  const stub = env.CHAT_ROOM.getByName(roomId);

  if (request.method === "POST") {
    const body = await request.json<{ userId: string; message: string }>();
    const result = await stub.sendMessage(body.userId, body.message);
    return Response.json(result);
  }

  const messages = await stub.getMessages();
  return Response.json(messages);
}
```

## Observability

Validate request bodies in the Worker before calling the DO; keep DO methods trusting their inputs. Use structured (JSON) console logging.

### Tail Workers (Production)

For production logging, use Tail Workers to forward logs:

```jsonc
// wrangler.jsonc
{
  "tail_consumers": [
    { "service": "log-collector" }
  ]
}
```

## Error Handling

Catch errors from DO stub calls in the Worker and map them to appropriate HTTP responses (e.g. 503). Errors thrown inside DO RPC methods propagate to the caller as rejected promises.

## Secrets Management

Set secrets via wrangler CLI, never in config files; they arrive on `env` like vars:

```bash
wrangler secret put API_KEY
```

## Development Commands

```bash
wrangler dev       # Local development
wrangler deploy    # Deploy
wrangler tail      # Tail logs
```
