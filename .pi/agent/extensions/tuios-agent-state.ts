// installed by tuios
// managed by tuios; `tuios integration install pi` overwrites this file and
// `tuios integration uninstall pi` removes it. Put your own extensions beside
// it instead of editing it.
// Local override: only nonempty normal answers report done; pi-retry backoff
// stays working. Failed/empty/cancelled stops report idle, not done/errored.
// TUIOS_INTEGRATION_ID=pi
// TUIOS_INTEGRATION_VERSION=2
// @ts-nocheck
//
// Reports Pi's turns to the tuios pane it runs in, through
// `tuios agent-hook pi`: session_start names the session, agent_start starts
// work and agent_settled ends it. ui_prompt_start says Pi is waiting on the
// person in a blocking prompt (a confirm, a choice, a line of input), and
// ui_prompt_end that the prompt was answered; both say whether a turn is
// running, so an answered prompt goes back to working or to rest. Only the TUI
// mode reports, since the print, JSON and RPC modes run with no terminal a
// pane could show.

import { spawn } from "node:child_process";

const TUIOS = "tuios";

function report(event, ctx, extra) {
  let sessionID = "";
  let sessionFile = "";
  try {
    const id = ctx?.sessionManager?.getSessionId?.();
    if (typeof id === "string") sessionID = id;
  } catch {}
  try {
    const file = ctx?.sessionManager?.getSessionFile?.();
    if (typeof file === "string") sessionFile = file;
  } catch {}
  const payload = JSON.stringify({
    hook_event_name: event,
    session_id: sessionID,
    transcript_path: sessionFile,
    ...extra,
  });
  try {
    const child = spawn(TUIOS, ["agent-hook", "pi", "--integration", "2"], {
      stdio: ["pipe", "ignore", "ignore"],
      windowsHide: true,
    });
    child.on("error", () => {});
    child.stdin.on("error", () => {});
    child.stdin.end(payload);
  } catch {
    // A report that cannot be sent must never break Pi.
  }
}

export default function (pi) {
  if (process.env.TUIOS_ENV !== "1" && !process.env.TUIOS_AGENT) {
    return;
  }
  let tui = false;
  let outcome;
  let finalAnswer = false;
  let retryID;
  let settledCtx;
  let cancelled = false;
  let promptDepth = 0;

  function reportRest() {
    if (!tui || !settledCtx || promptDepth > 0) return;
    const ctx = settledCtx;
    if (retryID !== undefined) {
      report("agent_start", ctx, {});
      return;
    }
    settledCtx = undefined;
    if (!cancelled && outcome === "completed" && finalAnswer) {
      report("agent_settled", ctx, {});
      return;
    }
    // An idle report ends activity without creating a successful completion or
    // an errored Inbox item. Do not use session_start, which resets session state.
    const pane = process.env.TUIOS_PANE_ID;
    const session = process.env.TUIOS_SESSION;
    if (!pane || !session) return; // Never fall back to the focused pane.
    try {
      const args = ["set-agent-state", "idle", "--session", session,
        "--window", pane, "--harness", "pi"];
      const id = ctx?.sessionManager?.getSessionId?.();
      if (typeof id === "string" && id) args.push("--agent-session-id", id);
      const child = spawn(TUIOS, args, {
        stdio: "ignore", windowsHide: true, timeout: 750, killSignal: "SIGKILL",
      });
      child.on("error", () => {});
    } catch {}
  }

  // pi-retry emits these synchronously before detached retries and after their
  // final settlement. Match receipts so an old loop cannot finish a newer one.
  pi.events.on("pi-retry:started", (event) => {
    if (!tui || !Number.isSafeInteger(event?.retryId)) return;
    retryID = event.retryId;
  });
  function retryEnded(event) {
    if (event?.retryId !== retryID || retryID === undefined) return;
    retryID = undefined;
    reportRest();
  }
  pi.events.on("pi-retry:completed", retryEnded);
  pi.events.on("pi-retry:cancelled", retryEnded);

  pi.on("session_start", (_event, ctx) => {
    tui = ctx?.mode === "tui";
    outcome = undefined;
    finalAnswer = false;
    retryID = undefined;
    settledCtx = undefined;
    promptDepth = 0;
    if (!tui) return;
    // A reload replaces the extension mid-turn without a new agent_start.
    report("session_start", ctx, { busy: ctx?.isIdle?.() === false });
  });
  pi.on("agent_start", (_event, ctx) => {
    outcome = undefined;
    finalAnswer = false;
    settledCtx = undefined;
    cancelled = false;
    if (tui) report("agent_start", ctx, {});
  });
  pi.on("agent_end", (event) => {
    const last = event.messages.findLast((message) => message.role === "assistant");
    finalAnswer = last?.stopReason === "stop" &&
      last.content.some((part) => part.type === "text" && part.text.trim()) &&
      !last.content.some((part) => part.type === "toolCall");
  });
  pi.on("agent_before_settle", (event) => { outcome = event.outcome; });
  pi.on("agent_settled", (event, ctx) => {
    if (!tui || ctx?.isIdle?.() === false) return;
    cancelled = event.aborted === true;
    settledCtx = ctx;
    reportRest();
  });
  pi.on("ui_prompt_start", (event, ctx) => {
    if (!tui) return;
    promptDepth++;
    report("ui_prompt_start", ctx, {
      kind: typeof event?.kind === "string" ? event.kind : "",
      title: typeof event?.title === "string" ? event.title : "",
      busy: ctx?.isIdle?.() === false,
    });
  });
  pi.on("ui_prompt_end", (event, ctx) => {
    if (!tui) return;
    promptDepth = Math.max(0, promptDepth - 1);
    report("ui_prompt_end", ctx, {
      kind: typeof event?.kind === "string" ? event.kind : "",
      busy: retryID !== undefined || ctx?.isIdle?.() === false,
    });
    reportRest();
  });
  pi.on("session_shutdown", () => {
    tui = false;
    retryID = undefined;
    settledCtx = undefined;
  });
}
