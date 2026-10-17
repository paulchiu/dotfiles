# Moving reminders between lists

Local testing on 2026-10-17 with remindctl 0.3.8 and macOS 27.0.1 produced:

| Move | Result |
| --- | --- |
| non-shared → non-shared | worked |
| shared → non-shared | ReminderKit error -3002 |
| non-shared → shared | ReminderKit error -3002 |

These observations are reported in [remindctl #104](https://github.com/openclaw/remindctl/issues/104). They do not establish that all shared-list moves fail on every OS version or that sharing is the only cause of -3002. Other edits succeeded on the tested reminders. The suspected mechanism is EventKit rejecting calendar reassignment across the sharing boundary; the private ReminderKit implementation is unverified. Check the installed version and upstream issue before applying this as a current limitation.

## Handling a failed move

Read the original reminder again and confirm its list and content. Keep it intact while diagnosing. Do not retry the same failed move repeatedly or change permissions based solely on this error. The CLI does not expose a supported sharing-status field in the tested version; ask Paul which lists are shared when needed.

Prefer asking Paul to move the item in Reminders.app if preserving its identity and metadata matters. Copy and delete changes the ID and may lose unsupported fields such as attachments, subtasks, tags, sections or collaboration metadata. Recurrence, alarms, URLs, completion state, priority and notes also need explicit comparison; copying just title, due date and notes is insufficient.

Only use copy and delete when Paul accepts the identity change and any known metadata loss. Capture the original with `info`, recreate all supported fields, then verify the new reminder against that snapshot. If anything cannot be preserved or verified, keep the original and report the gap. Run `delete <original-UUID> --dry-run --json --no-input`, show the exact original targeted, and obtain any deletion confirmation required by the main skill before `--force`. Do not interpret a successful add as proof of a lossless move.

## Optional store diagnostic

For deeper diagnosis only, `remindctl doctor --for-agent --json --no-input` may expose `richRead.databasePath`. This is a private schema and may change. In the tested store, non-zero `ZSHARINGSTATUS` together with non-empty `ZCKSERVERSHAREDATA` on `ZREMCDBASELIST` correlated with a shared list.

If a store inspection is necessary, open the source read-only and use SQLite's backup API to create a consistent snapshot in a private temporary directory, then query the snapshot. Copying only the main SQLite file can omit recent data held in its WAL. Remove the snapshot after use; it contains personal reminder data. Never write to the live store or fall back to AppleScript.
