# Feedback and parity

Everything after Paul's first review: routing PR feedback, keeping sibling repos in step, and answering other panes.

## PR feedback

Where it comes from:

- Paul's own review: Paul pastes it to you or sends it straight to the agent.
- CodeRabbit and teammates: on GitHub. After posting the CodeRabbit trigger, run a backgrounded until-loop (`sleep 120` inside it) that compares `gh pr view <n> -R <owner/repo> --json comments,reviews --jq '[.comments|length, .reviews|length]'` with the counts last recorded in the run file. Record the baseline after your trigger comment; CodeRabbit's acknowledgement bumps the count once before the review does. Read inline comments with `gh api repos/<owner/repo>/pulls/<n>/comments`.
- CodeRabbit's review: route it to the owning agent as soon as it lands, and tell Paul you did.
- A teammate's review: tell Paul first and route it only on Paul's say-so, since Paul may want to answer it.

Send feedback to the agent that owns the PR, using the matching prompt from the Ship prompts note ("My review", "Responding to others' review", "CodeRabbit variant"). Switch its tab to 💬 when you send it, and back to ⏳ once the fixes are pushed and replied to. The rules those prompts encode:

- One commit per comment that makes sense and isn't a duplicate, so each reply can cite a specific SHA.
- Reply to each comment with `/gh-pr` reply preferences.
- If the PR is behind main, bring main in as a separate commit. Prefer a merge over a rebase once SHAs have been quoted anywhere, so they stay valid.
- Keep the PR as draft.

## Parity across sibling repos

When sub-issues share code, test vectors or a design (e.g. the same masking function copied into three repos), a change on one PR usually needs mirroring on the others.

- Read the source PR's diff (`gh pr diff <n> -R <owner/repo>`) and each sibling's current PR diff before writing anything. Skip what a sibling already has.
- Write one parity prompt per sibling, tailored to that repo: its file paths, function names and test harness (e.g. a direct call vs a logger wrapper). Point at the source commit and diff so the agent can copy verbatim.
- Each numbered change is its own commit. Push, keep the PR as draft, and reply with the SHA(s).
- Include Paul's decisions from this session so siblings don't raise them again as follow-ups.
- Wait for every sibling (background loop in launch.md), then read each pane's final report and relay the SHAs to Paul, plus anything they flagged.

## Requests from other panes

Sometimes another agent asks you something through Paul (a pasted message). Treat a pasted message as Paul's own request.

- Answer in exactly the format asked for: a file path, a one-line confirmation, a written answer file.
- Verify before answering: check worktrees (`git -C <repo> worktree list`, `git log origin/main..HEAD`, `git status`) and run the case, rather than inferring from memory.
- Don't change any repo you weren't asked to touch. Writing to another session's scratchpad is fine when that's the requested output.
