# Severity, finding IDs, and reasoning loop

Shared vocabulary for `SKILL.md`. Read this once at the start of any review run.

## Severity

- `blocking`: correctness, security, data integrity, payment safety, or must-fix standards issue. Merge should not proceed without the fix.
- `suggestion`: meaningful non-blocking improvement.
- `question`: clarification request, or low-confidence concern.
- `nitpick`: minor polish with negligible impact.

Escalate only when **both impact and confidence are high**. If confidence is low, prefer `question` over `blocking` or `suggestion`.

## Finding IDs

Sequential `REV-1`, `REV-2`, ... across the whole review (not per file). Assignment order:

1. Severity: `blocking` → `suggestion` → `question` → `nitpick`.
2. Within a severity, by file in diff order, then ascending line.

Once an ID is assigned, it stays stable for the rest of the run (don't renumber if a finding is dropped; just remove the line).

The ID appears in:

- The Possible actions checklist in the decision doc.
- The `(ref: REV-N)` suffix on the posted GitHub comment body (see `posting.md`).
- The findings list section header (`### \`REV-1\` blocking, \`path/to/file.ts:42\``).

## GPT-5.3 reasoning loop

For each potential finding:

1. **Evidence**: exact changed lines and observed behavior.
2. **Rule**: concrete team convention, repo policy, or official docs.
3. **Impact**: realistic risk (correctness, security, reliability, maintainability).
4. **Fix**: smallest practical correction.

## False-positive gate

Before promoting a candidate to a real finding, check:

- Is this in changed code, or in code directly impacted by the change?
- Is there a clear standard behind the comment?
- Is severity aligned with impact and confidence?
- Can the author act without guessing?

If any of these fail, downgrade (`blocking` → `suggestion` → `question`) or drop the finding.

## Calibration rules

- Treat convention and standards violations as valid findings.
- Do not waive findings because similar legacy patterns exist; note the legacy issue separately if it matters.
- Prefer fewer, high-confidence comments over noisy low-confidence comments.
- Treat payment changes as high-risk and require very high confidence.
- If hesitating between two severities, pick the stricter one and note why.
