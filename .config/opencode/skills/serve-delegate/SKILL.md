---
name: serve-delegate
description: "Delegate Serve work to a Coder workspace agent, or check on a delegated job."
---

# Serve delegate (local wrapper)

This wrapper only sets the description. The workflow lives upstream in the serve-devcontainer checkout, so pulls keep it current.

Before doing anything, read `/Users/paul/dev/serve-devcontainer/skills/serve-delegate/SKILL.md` in full and follow it, with one substitution: skip its "Locate the launcher" step and use these resolved paths.

- Checkout: `/Users/paul/dev/serve-devcontainer`
- Launcher: `/Users/paul/dev/serve-devcontainer/bin/serve-env`
- Run every launcher command from the checkout, e.g. `(cd /Users/paul/dev/serve-devcontainer && bin/serve-env claude coder:<ws> status <job-id>)`, and keep task-file paths absolute. mise resolves Node per directory, and the job runner refuses anything but the checkout's Node 24.

## Local notes

- Name a new workspace for a Linear issue `<issue-id-lowercase>-<short-slug>`, e.g. `rr-411-service-charge-drawer`, so the Coder list says what each one is for. Coder allows only letters, digits and single hyphens, at most 32 characters, and has no display name, so `[RR-411] ...` is impossible. Without an issue, use a short task slug.

- Inside a workspace, `https://serve.mryum.local` gives no response (`000`) by design. Don't treat that as a fault or ask the executor to fix it. Browser checks of the guest app should target the ephemeral environment's domain, which exists once the task has a draft PR. A task with no PR verifies through Tilt health instead.

If the upstream file is missing, report it and stop. Do not clone, pull or switch branches without asking.
