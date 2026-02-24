# Team PR References

This folder vendors team PR guidance so the skill has no external file dependency.

## Read Order

1. `pull-request-review-guidelines.md`
2. `other-team-pr-preferences.md`

## Quick Rules

- Keep review comments actionable and line-targeted.
- Prioritize correctness, user impact, and security over style-only feedback.
- Treat standards and convention violations as real findings.
- Prefer high-confidence comments; use `question` when confidence is low.
- Require explicit reasoning when behavioral changes ship without tests.
- Treat payment changes as high-risk and require very high confidence.
- Keep migrations fail-fast and avoid hidden database behavior.
- Follow repo-local feature flag style and avoid introducing new divergence.
- Favor concrete fix guidance over abstract advice.
