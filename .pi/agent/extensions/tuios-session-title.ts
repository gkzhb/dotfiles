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

  // The rail's agent row gives the note line about 22 cells beside the context
  // usage, and a token that does not fit is dropped whole rather than cut. So a
  // reported title is clamped to what fits; the pane title bar, which comes
  // from Pi's own OSC title, keeps the whole thing. Set
  // TUIOS_SESSION_TITLE_MAX_CELLS to change the room, e.g. after widening the
  // rail with appearance.sidebar.width.
  const maxCells = Number.parseInt(process.env.TUIOS_SESSION_TITLE_MAX_CELLS ?? "", 10) > 0
    ? Number.parseInt(process.env.TUIOS_SESSION_TITLE_MAX_CELLS!, 10)
    : 22;

  // Display width: a CJK or emoji cell is two columns in a terminal, which is
  // what decides whether the rail keeps a token.
  function charCells(ch: string): number {
    const cp = ch.codePointAt(0)!;
    if (cp === 0x200d || cp === 0xfe0f || (cp >= 0x0300 && cp <= 0x036f)) return 0;
    if (
      (cp >= 0x1100 && cp <= 0x115f) ||
      (cp >= 0x2e80 && cp <= 0x303e) ||
      (cp >= 0x3041 && cp <= 0x33ff) ||
      (cp >= 0x3400 && cp <= 0x4dbf) ||
      (cp >= 0x4e00 && cp <= 0xa4cf) ||
      (cp >= 0xa960 && cp <= 0xa97f) ||
      (cp >= 0xac00 && cp <= 0xd7a3) ||
      (cp >= 0xf900 && cp <= 0xfaff) ||
      (cp >= 0xfe10 && cp <= 0xfe19) ||
      (cp >= 0xfe30 && cp <= 0xfe6f) ||
      (cp >= 0xff00 && cp <= 0xff60) ||
      (cp >= 0xffe0 && cp <= 0xffe6) ||
      (cp >= 0x1f300 && cp <= 0x1f64f) ||
      (cp >= 0x1f900 && cp <= 0x1f9ff) ||
      (cp >= 0x20000 && cp <= 0x3fffd)
    ) return 2;
    return 1;
  }

  function clampCells(text: string, max: number): string {
    if ([...text].reduce((w, ch) => w + charCells(ch), 0) <= max) return text;
    const budget = Math.max(1, max - 1); // one cell for the ellipsis
    let out = "";
    let width = 0;
    for (const ch of text) {
      const w = charCells(ch);
      if (width + w > budget) break;
      out += ch;
      width += w;
    }
    return `${out.replace(/\s+$/, "")}\u2026`;
  }

  function normalize(name: string | undefined): string {
    const clean = stripVTControlCharacters(name ?? "")
      .replace(/[\u0000-\u001f\u007f-\u009f]/g, " ")
      .replace(/\s+/g, " ")
      .trim();
    const cut = clampCells(clean, maxCells);
    // tuios cuts a value at 80 characters of its own; this is the same floor.
    return [...cut].slice(0, 80).join("");
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
