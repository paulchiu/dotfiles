# Other Team PR Preferences

## Scope and Risk

- Payment changes must be highly reliable and reviewed with very high confidence.

## Core Constraints

- Do not interpolate variables into log or exception message strings.
- Avoid non-null assertions (`!`) unless truly unavoidable.
- Feature flags should prefer verb names (for example `enableFoo`).
- Use repo-local flag style:
  - POS/VIM often prefers direct flag references.
  - Serve often uses constants for references.
  - Follow existing local patterns in the target repo.

## PR Expectations

- Describe acceptance criteria from the guest/user perspective, not only API perspective.
- Include context on objective and how the PR fits into a broader sequence.
- Include end-to-end evidence (for example Loom) when behavior changes are user-visible.

## Implementation Preferences

- Migrations should fail fast; avoid `IF EXISTS`.
- Create indexes with `CREATE INDEX CONCURRENTLY`.
- Keep audit trails in DAOs.
- Keep DAOs wrapped by services.
- Avoid implicit database cascades.
- Prefer `Promise.allSettled` over `Promise.all`.
- Prefer destructured arguments when more than two arguments are passed.
- Avoid floating-point money math.
- Do not prefix used variables with `_`.
- Prefer `undefined` for TS/non-React and `null` for React rendering.
- In Serve Frontend, prefer `menuAvailability` for ordering checks.
- Use `applyUtmToUrl` for UTM handling.
- In Serve Frontend, `/v2/` is considered the active current path as of November 20, 2025; duplicated components may be legacy v1.
- Do not use default Tailwind classes where design tokens should be used.

## Terraform

- For CRDB changes, prefer explicit target scoping to limit unintended changes.

## Build / CI Conventions

- Buildkite Node-side `pipeline.yml` steps must use the internal builder image `${DOCKERTOOLS_REGISTRY}/base/node-24-install:v3` with the `ecr#v2.12.0: login: true` plugin, not Docker Hub images like `node:24-bookworm-slim` or plain `node:24`. Reference repos: `serve-frontend` and `manage-frontend` (`pipeline.yml`). Core-ordering services (`bill-api`, `payment-api`, `order-api`, `order-worker`) use `pipeline.ts` via `@mr-yum/service-pipeline` and run inside the just-built service image instead; if a repo is on `pipeline.ts`, that path is fine. Evidence: https://github.com/mr-yum/stable-api-docs/pull/171#discussion_r... (Benno007 flag, fixed in commit a672009). Flag any new pipeline step pulling from Docker Hub or a non-ECR registry as `blocking` (supply-chain / org policy).

## Testing Preferences

- Prefer readable fixture values over realistic-looking random values.
- Prefer descriptive assertions over snapshots/object-wide comparisons.
- Keep snapshots short (about 12 lines max) when snapshots are used.
- Avoid `test-id` when stronger queries are available.

## Core Ordering (cart/order paths in `manage-api`)

Apply when reviewing changes under `src/modules/cart/`, `src/modules/cartValidation/`, `src/modules/order/`, or related `schema.gql` enums/types. Standards observed from Core Ordering reviewers (Benno007, OscarAvellan).

- New persistence reads/writes in cart/order code should use Prisma, not TypeORM. TypeORM is being removed from manage-api, so flag any newly added TypeORM query as a `suggestion` to use Prisma; existing call sites in the same file are fine to leave alone for the PR. Evidence: https://github.com/mr-yum/manage/pull/3204#discussion_r3222779310
- Guest-facing validation error copy must match the frontend string the guest actually sees. When adding or modifying a `CartValidationError` message (or any other text surfaced verbatim to guests), look up the equivalent frontend string and reuse it. The EONX session-expiry copy is the canonical example: `"Your session has expired! Please click the Home tab and select Order at Table to start again."` Evidence: https://github.com/mr-yum/manage/pull/3204#discussion_r3222778208
- Public schema additions (GraphQL enum values, proto types, new error codes) need an explicit downstream-consumer follow-up. When a new value must be handled by serve-frontend, manage-frontend, or guest-gateway, raise it as a `question` and recommend a follow-up ticket; do not assume frontends will discover the new value passively. Evidence: https://github.com/mr-yum/manage/pull/3204#discussion_r3222786543
