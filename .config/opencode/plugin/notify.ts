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
      if (event.type !== "session.idle") {
        return;
      }
      /** Current session id */
      const sid = event.properties.sessionID;
      const session = await client.session.get({
        path: { id: sid },
      });
      const msgs = await client.session.messages({ path: { id: sid } });
      // Check this is the main session that user talks to.
      const isMainChatSession =
        // top session
        !session.data?.parentID ||
        // has more than one user message
        (msgs.data?.filter((message) => message.info.role === "user").length ??
          0) > 1;
      if (!isMainChatSession) {
        return;
      }
      const sessionTitle = session?.data?.title ?? "";

      // Check if terminal-notifier exists before executing
      try {
        await $`which terminal-notifier`.quiet();
        await $`terminal-notifier -message "Session \"${sessionTitle}\" completed!" -title "OpenCode"'`;
      } catch {
        // terminal-notifier not found, skip notification
      }
    },
  };
};
