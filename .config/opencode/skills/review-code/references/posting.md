# Posting to GitHub

How to post inline review comments, approvals, or change requests once the user has ticked actions in the decision doc.

## Never post without explicit user tick

A prior session's approval doesn't carry over. The user must tick specific actions in the current turn before anything is posted, approved, or change-requested.

## Comment body wrapper

Every posted comment uses this exact wrapper:

````md
LLM note: <one-line short version, non-redundant with the opening paragraph>

<details>
  <summary>LLM reasoning</summary>

<plain opening paragraph stating the issue and the expected fix direction; no severity label>

Why this matters: 1-3 sentences on concrete impact.

Recommended change

```<lang>
// minimal fix sketch or exact replacement
```

Patch-style diff (optional)

```diff
- old line(s)
+ new line(s)
```

Current code (optional)

```<lang>
// 3-12 lines from the changed code near the target line
```

References (optional)

- [Changed line link](https://github.com/<org>/<repo>/blob/<head-sha>/path/to/file.ts#L<line>)
</details>

(ref: REV-N)
````

Rules:

- Plain markdown only inside the body, with `<details>` / `<summary>` as the outer wrapper.
- Start with `LLM note:` on the first line.
- Opening paragraph follows the `<summary>` directly, with no `Suggestion:` / `Blocking:` / `Nitpick:` / `Question:` prefix.
- `(ref: REV-N)` is the **last line of the comment body**, outside `</details>`. This is mandatory.
- Severity lives in the decision doc and the inline checklist only, never in the GitHub comment body.
- If the user supplies their own framing text, prepend `My note: <text>` above the `LLM note:` line.
- Code snippets must match the target project's style (single vs double quotes, semicolons, formatting). Read at least one nearby file in the changed code before drafting snippets so house style is preserved.
- Australian spelling. Neutral-professional tone in posted comments, even when the internal reasoning was hostile.
- No em dashes.

## Posting inline comments via `gh api`

For each finding the user ticked:

1. Resolve repo from `gh pr view --json url,headRefOid,headRefName,baseRefName`. Use `headRefOid` as `commit_id`.
2. Confirm the line number matches the changed-side line in the diff (`gh pr diff` or `git diff --unified=...`).
3. Write the body to a temp file with a **non-`.md` extension** (e.g. `/tmp/rev-1.body` or `.txt`) so Prettier-style Write hooks don't reformat code snippets inside the body. Prefer a heredoc via Bash:

   ```bash
   cat > /tmp/rev-1.body <<'BODY'
   LLM note: ...
   <details>
     <summary>LLM reasoning</summary>
   ...
   </details>

   (ref: REV-1)
   BODY
   ```

4. Serialise to JSON:

   ```bash
   node -e "const fs=require('fs'); const body=fs.readFileSync('/tmp/rev-1.body','utf8'); fs.writeFileSync('/tmp/rev-1.json', JSON.stringify({ body, commit_id: '<sha>', path: '<file>', line: <n>, side: 'RIGHT' }));"
   ```

5. POST:

   ```bash
   gh api repos/<org>/<repo>/pulls/<num>/comments -X POST --input /tmp/rev-1.json --jq '{html_url, path, line}'
   ```

6. If the finding doesn't anchor to a changed line in the diff hunk (e.g. unchanged import, whole-file pattern), post as **file-level**: `subject_type: "file"`, omit `line` and `side`. Include the relevant lines as a fenced block in the body for context.

7. After posting, capture each returned `html_url` and report all URLs back to the user.

8. Sanity-check the returned `body` to confirm fenced code and quotes were preserved. If mangled, PATCH the comment with the same payload:

   ```bash
   gh api repos/<org>/<repo>/pulls/comments/<comment-id> -X PATCH --input /tmp/rev-1.json
   ```

Avoid:

- Inline `$'...'` bodies for Markdown-heavy comments; shell quoting silently strips backticks or `''` in code samples.
- Mixing review-comment fields passed via `-f` / `-F` with `--input` for the body payload; this can produce HTTP 422 errors where GitHub reports `commit_id`, `path`, or `line` as missing.

## Approving or requesting changes

Only when the user explicitly ticks the action:

```bash
gh pr review <PR_NUMBER> --repo <org>/<repo> --approve --body "<short summary>"
# or
gh pr review <PR_NUMBER> --repo <org>/<repo> --request-changes --body "<short summary>"
```

### Review-level body style

**Ultra-terse: one short sentence, ~10 words.** It's a vibe-check on top of the inline comments, not a restatement. Do **not** recap findings, AC trace, test counts, or repeat what's already in the inline comments.

Pattern: `<one-line sentiment>, <brief tally of inline findings>.`

Examples (casual abbreviations like "LGTM" are fine):

- `LGTM, just one change requested and a nit pick.`
- `Looks good, two nit picks inline.`
- `One blocker inline, see REV-1.`
- `Ship it.` (for `--approve` with nothing to flag)

Tone: no em dashes; Australian spelling; "nit pick" as two words.

Verify the review was recorded:

```bash
gh pr view <PR_NUMBER> --repo <org>/<repo> --json reviews \
  --jq '.reviews[-3:] | map({author: .author.login, state, submittedAt})'
```
