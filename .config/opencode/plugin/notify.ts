import type { Plugin } from "@opencode-ai/plugin";

export const NotificationPlugin: Plugin = async ({
  project,
  client,
  $,
  directory,
  worktree,
}) => {
  return {
    event: async ({ event }) => {
      // Send notification on session completion
      if (event.type === "session.idle") {
        const session = await client.session.get({
          path: { id: event.properties.sessionID },
        });
        const sessionTitle = session?.data?.title ?? "";
        
        // Check if terminal-notifier exists before executing
        try {
          await $`which terminal-notifier`.quiet();
          await $`terminal-notifier -message "Session \"${sessionTitle}\" completed!" -title "OpenCode"'`;
        } catch {
          // terminal-notifier not found, skip notification
        }
      }
    },
  };
};
