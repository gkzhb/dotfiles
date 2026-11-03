// User-owned companion to tuios-agent-state.ts; integration install will not overwrite it.
// Reports only the Pi conversation title, without changing pane names or agent state.
import { execFile } from "node:child_process";
import { stripVTControlCharacters } from "node:util";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  const pane = process.env.TUIOS_PANE_ID;
  const session = process.env.TUIOS_SESSION;
  if (process.env.TUIOS_ENV !== "1" || !pane || !session) return;

  // Child Pi processes inherit pane coordinates, but must not overwrite the parent's title.
  const owner = process.env.TUIOS_PI_TITLE_OWNER;
  if (owner && owner !== String(process.pid)) return;
  process.env.TUIOS_PI_TITLE_OWNER = String(process.pid);

  let tui = false;
  let pending: string | undefined;
  let sending: Promise<void> | undefined;

  function normalize(name: string | undefined): string {
    const clean = stripVTControlCharacters(name ?? "")
      .replace(/[\u0000-\u001f\u007f-\u009f]/g, " ")
      .replace(/\s+/g, " ")
      .trim();
    return [...clean].slice(0, 80).join("");
  }

  function write(title: string): Promise<void> {
    return new Promise((resolve) => {
      // No shell interpolation; always address this pane, not whichever pane has focus.
      try {
        execFile("tuios", [
          "set-agent-meta", "--session", session!, "--window", pane!,
          "--source", "pi-session-title", `session_title=${title}`,
        ], { timeout: 1000, windowsHide: true }, () => resolve());
      } catch {
        resolve(); // A missing or unavailable tuios must never break Pi.
      }
    });
  }

  function report(name: string | undefined): Promise<void> {
    pending = normalize(name);
    // Serialize delivery, retaining only the newest pending title while tuios is slow.
    if (!sending) {
      sending = (async () => {
        while (pending !== undefined) {
          const title = pending;
          pending = undefined;
          await write(title);
        }
      })().finally(() => {
        sending = undefined;
        // An event may arrive between the drain finishing and this cleanup microtask.
        if (pending !== undefined) void report(pending);
      });
    }
    return sending;
  }

  pi.on("session_start", (_event, ctx) => {
    tui = ctx.mode === "tui";
    if (tui) void report(pi.getSessionName());
  });
  pi.on("session_info_changed", (event) => {
    if (tui) void report(event.name);
  });
  pi.on("agent_start", () => {
    if (tui) void report(pi.getSessionName());
  });
  pi.on("agent_settled", () => {
    if (tui) void report(pi.getSessionName());
  });
  pi.on("session_shutdown", async () => {
    if (!tui) return;
    tui = false;
    await report(undefined); // Clear just our field; keep all other metadata intact.
  });
}
