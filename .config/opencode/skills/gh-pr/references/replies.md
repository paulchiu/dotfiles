# Replying to review comments

How Paul replies to reviewer comments (CodeRabbit, bots, humans) on a PR. Voice
follows the `writing-tone` skill: lead with substance, no em dashes, single
quotes, Australian spelling, backticks only on real code tokens, end at the last
real point. These are threaded replies, so keep them short.

Post a threaded reply to an inline review comment with:

```bash
gh api repos/<owner>/<repo>/pulls/<pr>/comments \
  -f body="<reply>" \
  -F in_reply_to=<comment_id>
```

(For a top-level PR conversation comment, use `gh pr comment <pr> --body "..."`.)

## When you agree or it's a straight fix

Terse. State the fix and the commit that carries it. No preamble, no thanks.

- `Fixed in 56ecf5a0d.`
- `Agree, updated in 56ecf5a0d.`

Add one clause only if the fix isn't self-evident from the diff (what changed,
or a scope note on what you deliberately left alone). Still one or two lines.

## When you disagree

Evidence-based, not a flat 'no'. Structure:

1. Ground it in observations: what the code, tests, or docs actually show ('the
   formatter drops meta at `attachExtensions`', 'the unit test already covers the
   internal shape'). Cite the location where it helps.
2. If relevant, name your own preference for the tradeoff ('I'd rather keep the
   wire-contract assertion in the integration spec than duplicate it').
3. State the lean, hedged: 'I am leaning towards X'. A verdict, not a decree.
4. Close with a line inviting the counter-argument ('happy to be talked out of
   it if ...', 'let me know if you're seeing a case I'm missing').

Keep it collaborative: you're proposing where you've landed and leaving the door
open, not winning the thread.

## Don't

- No validation openers ('Great catch', 'Good point', 'Fair point'); lead with
  the fix or the substance.
- No review-round internals (persona lenses, agent names, adversarial passes).
- Don't re-approve or resolve threads on the author's behalf; a push that adds a
  fix commit re-gates the PR to `REVIEW_REQUIRED` and needs the reviewer's own
  re-approval.
