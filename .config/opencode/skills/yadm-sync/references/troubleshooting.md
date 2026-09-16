# yadm-sync troubleshooting

Open this file only when a yadm command fails or reports impossible results. Follow the section that matches the symptom, then return to the workflow step you were on.

## Lock contention (`index.lock`)

**Symptoms:** `yadm add` or `yadm commit` fails with `Unable to create '.../index.lock': File exists`, or EPERM in a delegated process such as codex.

**Cause:** Another `yadm`/`git` process is mid-write against the bare repo. The repo lives at `$(yadm introspect repo)`; the lock file is `$(yadm introspect repo)/index.lock`.

**Fix procedure, in order:**

1. Check whether a live process holds the lock:

   ```bash
   REPO=$(yadm introspect repo)
   ls -l "$REPO/index.lock" 2>/dev/null
   lsof "$REPO/index.lock" 2>/dev/null
   pgrep -fl 'yadm|git.*'"$REPO" || true
   ```

2. If a live process owns it: run `sleep 2`, then re-run the failed command once. If it still fails: run `sleep 5`, then re-run once more. If it fails a third time, stop and report the error. Do not loop indefinitely.
3. If no process owns it (stale lock from a crashed or killed run, common after a codex EPERM): remove only the lock file, then retry the failed command:

   ```bash
   rm "$REPO/index.lock"
   ```

   Do NOT `rm -rf` anything else under `$REPO`.
4. If the contention is with the main Claude thread (codex was delegated and hit EPERM): stop the codex-side yadm work and have the main thread complete the sync. Two writers against the same yadm repo is the root cause; clearing the lock without fixing the contention will recur.
