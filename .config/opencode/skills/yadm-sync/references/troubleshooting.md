# yadm-sync troubleshooting

Open this file only when a yadm command fails or reports impossible results. Follow the section that matches the symptom, then return to the workflow step you were on.

## RTK rewrites yadm

**Symptoms:**

- `yadm status` reports a clean tree ("nothing to commit") for files in `~/.config/opencode/` or `~/.claude/` that you know were just changed.
- `yadm add <path>` fails with "outside repository".
- `yadm push` pushes to the wrong remote.

**Cause:** The Claude Code hook routes `yadm` through `rtk` (Rust Token Killer). Up to rtk `0.42.0`, rtk rewrites `yadm <cmd>` to `rtk git <cmd>`, which runs against the CWD repo instead of yadm's `--git-dir`/`--work-tree`. Tracked upstream as [rtk-ai/rtk#2077](https://github.com/rtk-ai/rtk/issues/2077), fix in flight at [rtk-ai/rtk#2078](https://github.com/rtk-ai/rtk/pull/2078).

**Fix procedure, in order:**

1. Confirm the user's committed workaround is still present. The yadm exclusion lives in `~/Library/Application Support/rtk/config.toml` (macOS) or `~/.config/rtk/config.toml` (Linux):

   ```bash
   grep yadm "$HOME/Library/Application Support/rtk/config.toml"
   ```

   Expected line inside `[hooks]`:

   ```toml
   exclude_commands = ["^yadm(?:$| )"]
   ```

2. If the exclusion is present: run `yadm` normally, no wrapping needed. If commands still misbehave, use the fallbacks in step 3 and report to the user that rtk may have regressed.
3. If the exclusion is missing (config wiped) or rtk has regressed, use one of these explicit forms for every yadm command in the workflow:

   ```
   rtk proxy yadm <cmd>                                               # bypass rtk's rewrite
   git --git-dir=$(yadm introspect repo) --work-tree="$HOME" <cmd>    # bypass rtk entirely
   ```

Once rtk-ai/rtk#2078 ships, the `exclude_commands` entry and this section become unnecessary.

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
