# Technical Posts & Code-Reference Writing

Rules for posts that discuss technical implementation with specific code, file, or symbol references (incident writeups, lessons-learned shares, test improvement suggestions, architecture proposals, PR-adjacent commentary). These conventions override the general "prefer prose over bullets" bias in the main skill; for technical diagnosis/proposal posts, paired bullet lists are the canonical "genuinely discrete items" case.

## When to apply

Apply when the post meets any of these triggers:

- Cites specific files, functions, classes, or line ranges in the codebase.
- Argues for a technical investment (add tests, add monitoring, refactor X).
- Summarises root causes of a bug or incident at the code level.
- Compares "what exists" against "what should exist" for production code.

Skip when the post is a general update, recognition, retro discussion, non-technical FYI, or people/process commentary. Fall back to the main skill's prose conventions for those.

## Rule 1: Diagnose and propose as paired bullet lists

When arguing "invest in X because Y", structure as two parallel bullet lists rather than interleaved prose:

- **Diagnosis list**: each bullet names a specific symbol or file, describes what it does today, and names why that's insufficient, with a `([GitHub](url#Lnn))` citation (see the code-location citation rule in the main skill).
- **Proposal list**: each bullet is a concrete action, mapped to the specific problem it addresses (see Rule 3).

Example shape:

```
Current coverage has gaps:

* `FunctionName` does X via Y ([GitHub](...)) but never asserts Z.
* `OtherFunction` validates A ([GitHub](...)), but no integration spec exercises B.
* `SomeSpec` checks C ([GitHub](...)) and nothing else.

A targeted investment would close these:

* Add test for Z (catches TICKET-1).
* Add integration spec for B (catches TICKET-2).
* Extend SomeSpec to cover D (catches TICKET-3).
```

The paired structure lets the reader scan gaps and remedies in two quick passes rather than parsing them out of paragraphs. A short linking sentence between the two lists ('A targeted investment would close these', 'These three changes would have blocked the incident') is welcome; a long preamble before the proposal list is not.

## Rule 2: Name what's absent, not just what's present

"Zero coverage for image upload/remove" lands harder than "the tests are limited". "No test re-opens an item to assert X survived" is more precise than "missing some assertions". Use these precise quantifiers when the underlying count is known:

- `zero` (exact count, when it's actually zero)
- `no` (for "there is no test that...")
- `sole` (for "the sole integration test covering...")
- `only` (for "only checks the name", "only asserts on success")

Avoid hedged quantifiers (`limited`, `some`, `a few`, `most`) when you can verify the exact number from the repo. Precision is the argument; hedging in a technical diagnosis reads as not having looked.

## Rule 3: Map each proposal to the specific problem it catches

Every proposal bullet should end with the ticket, incident, or failure mode it resolves, in parentheses:

- `Image upload → reload → assert the image URL (catches CUSM-795)`
- `Allergens edit → reload → assert saved value (catches CUSM-770)`

The mapping does three things: it forces scope honesty (you can't propose items that don't map to a real problem), it pre-empts "would this actually help" pushback, and it makes the set bulletproof against piecemeal descoping because dropping a proposal now has a named cost.

If a proposal doesn't map to a specific problem, either drop it or reframe the post; a speculative "nice to have" bullet undermines the concrete ones around it.

## Rule 4: Symbol-first bullets

Open technical bullets with the symbol as the subject, not with a pronoun, filler verb, or locative phrase:

- Good: `` `MenuItemImageUpload` calls `upload` via `useMutation(ManageMenuItemImageUploadDocument)` ([GitHub](...)) and only checks the returned `error` flag. ``
- Bad: `The component calls upload via useMutation and only checks the error flag.` (pronoun-first, citation has to be bolted on)
- Bad: `In MenuItemImageUpload.tsx, the upload mutation is called...` (locative-first, passive voice)

Symbol-first lets the reader scan for what's being discussed before reading the explanation, and it naturally pairs with the `Symbol` ([GitHub](url#Lnn)) citation convention: the symbol you lead with is the one you link.

## Supporting patterns

### Arrow notation for short sequences

Use `→` for test steps, data flow, and state transitions when the sequence is three to five steps:

- `read → edit → save → reload`
- `upload → reload → assert image URL`
- `mutation fires → FK unchanged → reloaded item shows stale image`

Avoid arrows when the sequence is longer than five steps (use a numbered list), when any step needs explanation (use prose), or for non-sequence relationships (don't write `A → B` to mean "A implies B").

### Backtick density

In technical posts, be aggressive with backticks. Function calls, document IDs, GraphQL mutation names, hook names, column names, error types, state values — all in backticks. The visual density signals "this is technical content" and separates the claims from the surrounding prose, so the reader's eye can jump between them. The main skill's rule ("format code identifiers, filenames, config keys, and CLI commands in backticks") is the floor; in technical posts, apply it more aggressively.

### Precise test-shape verbs

When describing what a test does or doesn't do, use the exact shape verbs: `seeds`, `mutates`, `re-fetches`, `asserts`, `reloads`, `exercises`, `pins`. Avoid generic verbs (`tests`, `covers`, `handles`). "No test re-opens an item to assert `allergens` survived a save" is more actionable than "coverage is lacking".

## Worked example

The following section (from a post-incident lessons-learned writeup) demonstrates all four rules working together: symbol-first bullets, precise quantifiers, citations, and a proposal list mapped to the underlying problems.

```
*Claude test improvement suggestion*

A quick cross-check of `manage-frontend` suggests the same bugs could have
been caught one layer up if we had round-trip coverage there too. The
mutations are wired and `cdnImage` is queried on the fragment, but nothing
in that repo asserts a mutation actually *persists*:

* `MenuItemImageUpload` calls `upload` and `remove` via
  `useMutation(ManageMenuItemImageUploadDocument)` /
  `useMutation(ManageMenuItemImageRemoveDocument)` ([GitHub](...#L99-L104))
  and only checks the returned `error` flag. No re-fetch, no assertion
  that `cdnImage` on the reloaded item reflects the mutation.
* `UpdateMenuItemDocument` is called from `MenuItemDrawer` ([GitHub](...#L546))
  and the form validates `allergens` as a nullable array ([GitHub](...#L624)),
  but no integration spec exercises a read→edit→save→reload cycle that
  would have tripped CUSM-770's `PrismaClientValidationError`.
* The sole critical menu-item Playwright spec ([GitHub](...#L5)) creates,
  verifies, and deletes an item but only asserts the name appears in the
  list. Zero coverage for image upload/remove, and no test re-opens an
  item to assert that `allergens` or `cdnImage` survived a save.

A small, targeted Playwright spec would have blocked all three regressions
at the frontend gate:

* Image upload → reload → assert the image URL on the reloaded item
  resolves to the uploaded asset (catches CUSM-795).
* Image remove → reload → assert the image field is cleared
  (catches CUSM-796).
* Allergens edit on a previously-empty item → reload → assert the saved
  value (catches CUSM-770).

Each case mutates, re-fetches, and asserts the field, which is the exact
shape our current e2e suite is missing.
```

Things worth pointing out in the example:

- Each diagnosis bullet opens with a symbol, cites the exact line, names what the code does, and names what it doesn't do ('only checks the returned `error` flag', 'no re-fetch', 'no integration spec exercises').
- Each proposal bullet maps to a specific ticket.
- 'Zero coverage', 'sole critical', 'no test re-opens' are precise quantifiers keyed to what's actually in the repo, not hedged summaries.
- Arrow notation anchors the test shape (`read→edit→save→reload`, `upload → reload → assert`).
- Backticks sit on every symbol, mutation name, document, and error type.
