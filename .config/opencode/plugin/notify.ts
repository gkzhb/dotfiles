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
        await $`terminal-notifier -message "Session \"${sessionTitle}\" completed!" -title "OpenCode"'`;
      }
    },
  };
};
