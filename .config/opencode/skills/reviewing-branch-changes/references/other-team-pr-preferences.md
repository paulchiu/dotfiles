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

## Testing Preferences

- Prefer readable fixture values over realistic-looking random values.
- Prefer descriptive assertions over snapshots/object-wide comparisons.
- Keep snapshots short (about 12 lines max) when snapshots are used.
- Avoid `test-id` when stronger queries are available.
