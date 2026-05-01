// Sends a Telegram notification when an OpenCode session becomes idle.
// Loaded globally from ~/.config/opencode/plugins/.

const NOTIFY_COMMAND = "/Users/paul/bin/telegram-notify"

export const TelegramNotifyPlugin = async ({ $, client, directory, worktree }) => {
  return {
    event: async ({ event }) => {
      if (event.type !== "session.idle") return

      const location = worktree || directory || process.cwd()
      const payload = JSON.stringify({
        title: "[OpenCode]",
        hook_event_name: "session.idle",
        session_id: event.properties?.sessionID,
        "last-assistant-message": `Session completed - ready for input.\n${location}`,
      })

      try {
        await $`${NOTIFY_COMMAND} ${payload}`.quiet()
      } catch (error) {
        await client?.app?.log?.({
          body: {
            service: "telegram-notify",
            level: "error",
            message: "Failed to send OpenCode Telegram notification",
            extra: { error: String(error) },
          },
        })
      }
    },
  }
}
