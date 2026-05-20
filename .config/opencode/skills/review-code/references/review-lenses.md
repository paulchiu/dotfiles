# Review lenses

Two passes over the diff. Round 1 is the principal-engineer sweep. Round 2 is the hostile adversarial pass. The lenses below are the full toolkit for both rounds. In round 2, treat the round-1 findings as a draft to attack, not a finished list.

## Round 1 lenses (principal-engineer sweep)

### PR context

- WHY of the change is clear from the body.
- Scope and sizing are reasonable.
- Stakeholder/user impact is acknowledged.
- Coupling between this PR and surrounding work is explained if non-trivial.

### Code quality

- KISS, maintainability, naming clarity, mutation minimisation.
- YAGNI: no speculative code, no re-implementations of existing utilities.
- Refactors don't smuggle in behavior changes.

### TypeScript

- Avoid `any`; prefer `unknown`.
- Avoid non-null assertions (`!`) unless truly unavoidable.
- `undefined` vs `null` follows repo convention (TS/non-React: `undefined`; React rendering: `null`).
- Destructured arguments when more than two are passed.
- Repo-local `type` vs `interface` convention respected.

### Team conventions

- No variable interpolation in log/exception message strings.
- Feature flags prefer verb names (`enableFoo`); use repo-local flag style (POS/VIM direct, Serve constants).
- `Promise.allSettled` over `Promise.all` where partial failure matters.
- Audit trails in DAOs; DAOs wrapped by services; no implicit DB cascades.
- No float for money math.
- Don't prefix used variables with `_`.
- No default Tailwind classes where design tokens should be used.

### Data and infra

- Migrations fail fast; avoid `IF EXISTS`.
- Indexes created with `CREATE INDEX CONCURRENTLY`.
- Schema changes have a backfill plan.
- Terraform CRDB changes use explicit target scoping.

### Tests

- Tests cover the behavioral changes; missing tests need explicit justification.
- Readable fixtures over realistic-looking random values.
- Descriptive assertions over snapshots/object-wide comparisons.
- Snapshots kept short (~12 lines max).
- Stronger queries than `test-id` when available.
- Mocking style matches nearby tests.

### Repo-specific lenses

If the diff touches:

- `manage-frontend` or `@mr-yum/frontend-ui` → load `manage-frontend.md`.
- `manage-api` cart/order paths (`src/modules/cart/`, `src/modules/cartValidation/`, `src/modules/order/`, schema.gql enums/types) → apply the Core Ordering rules in `other-team-pr-preferences.md` (Prisma over TypeORM for new code, guest-facing copy parity, public-schema additions need downstream follow-up).

## Round 2 lenses (adversarial pass)

Hunt actively. Each lens is an attack vector against the diff.

### Bugs

- Off-by-one (`<` vs `<=`, length vs index).
- Null/undefined deref.
- Wrong comparator (`==` vs `===`).
- Inverted boolean.
- Swapped args.
- Mutation of inputs.
- Async without `await`.
- Missing return.
- Switch fallthrough.

### Regressions

- Removed validation.
- Loosened types.
- Removed or weakened test assertion.
- Behavior change in a shared helper used elsewhere (grep callers of changed exports).

### Missing edge cases

- Empty array; single element; max size.
- Unicode / emoji.
- Timezone boundaries; DST.
- Concurrent calls.
- Partial failure.
- Retry semantics; idempotency.

### Security

- Input not sanitised.
- Auth check bypassed.
- Secrets in logs.
- SQL / command injection.
- XSS surface.
- Missing rate limit on a new endpoint.

### Data integrity

- Migration without rollback.
- Schema change without backfill plan.
- Float for money math.
- Non-atomic multi-write.
- Missing index on a new query path.

### Test quality

- Snapshot-only assertions where behavior matters.
- Mocked away the thing under test.
- Flaky timer / network usage.
- No negative case.
- No boundary case.

### Build / CI supply chain (blocking)

In Buildkite `pipeline.yml` steps, any Docker Hub or non-ECR base image (e.g. `node:24`, `node:24-bookworm-slim`) instead of the internal `${DOCKERTOOLS_REGISTRY}/base/node-24-install:v3` + `ecr#v2.12.0: login: true` plugin is `blocking`. Reference repos: `serve-frontend`, `manage-frontend`. Repos on `pipeline.ts` via `@mr-yum/service-pipeline` use the just-built service image instead, which is also fine.

Past incident: `mr-yum/stable-api-docs#171`.

## How to use these lenses

Round 1: walk the diff file-by-file, apply the principal-engineer lenses, draft findings with the reasoning loop in `severity-and-ids.md`.

Round 2: walk the diff again with the adversarial lenses. For each finding from round 1:

- Is the impact realistic? If not, downgrade or drop.
- Is there a clear rule? If not, downgrade to `question`.
- Did I miss anything in this file under the adversarial lenses?

Round 2 runs exactly once. Don't loop.
