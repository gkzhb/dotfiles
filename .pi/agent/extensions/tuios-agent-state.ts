// installed by tuios
// managed by tuios; `tuios integration install pi` overwrites this file and
// `tuios integration uninstall pi` removes it. Put your own extensions beside
// it instead of editing it.
// Local override: only nonempty normal answers report done; pi-retry backoff
// stays working. Failed/empty/cancelled stops report idle, not done/errored.
// Keep idle commands in the v3 FIFO with lifecycle and transcript reports.
// TUIOS_INTEGRATION_ID=pi
// TUIOS_INTEGRATION_VERSION=3
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
import { watch } from "node:fs";
import { basename, dirname } from "node:path";

const TUIOS = "tuios";

// Delivery is best-effort, bounded and FIFO for retained state reports. Keep
// only the newest adjacent metadata update; a slow daemon must not accumulate
// an unbounded promise chain or make /reload wait for every obsolete leaf.
const MAX_PENDING = 32;
const MAX_REPORT_BYTES = 64 * 1024;
const DRAIN_MS = 1000;
const queue = [];
let sending = false;
let activeChild;
let idle;
let lastSelection = "";

function send(payload, args) {
  return new Promise(resolve => {
    try {
      const child = spawn(TUIOS, args ?? ["agent-hook", "pi", "--integration", "3"], {
        stdio: args ? "ignore" : ["pipe", "ignore", "ignore"],
        windowsHide: true,
        timeout: args ? 750 : 2000,
        ...(args ? { killSignal: "SIGKILL" } : {}),
      });
      activeChild = child;
      child.on("error", resolve);
      child.on("close", () => {
        if (activeChild === child) activeChild = undefined;
        resolve();
      });
      child.stdin?.on("error", () => {});
      child.stdin?.end(payload);
    } catch {
      resolve();
    }
  });
}

async function pump() {
  if (sending) return;
  sending = true;
  try {
    while (queue.length) {
      const next = queue.shift();
      await send(next.payload, next.args);
    }
  } finally {
    sending = false;
    idle?.();
    idle = undefined;
  }
}

function enqueue(payload, key, args) {
  if (Buffer.byteLength(payload) > MAX_REPORT_BYTES) return;
  const last = queue.at(-1);
  if (key && last?.key === key) {
    last.payload = payload;
    return;
  }
  if (queue.length >= MAX_PENDING) {
    const obsolete = queue.findIndex(report => report.key);
    queue.splice(obsolete < 0 ? 0 : obsolete, 1);
  }
  queue.push({ payload, key, args });
  void pump();
}

async function drain() {
  if (!sending && !queue.length) return;
  let timer;
  await Promise.race([
    new Promise(resolve => { idle = resolve; }),
    new Promise(resolve => { timer = setTimeout(resolve, DRAIN_MS); }),
  ]);
  clearTimeout(timer);
  idle = undefined;
  queue.length = 0;
  activeChild?.kill(); // only our reporting child, never the daemon or Pi
}

function report(event, ctx, extra) {
  let sessionID = "";
  let sessionFile = "";
  let leaf;
  try {
    const id = ctx?.sessionManager?.getSessionId?.();
    if (typeof id === "string") sessionID = id;
  } catch {}
  try {
    const id = ctx?.sessionManager?.getLeafId?.();
    if (typeof id === "string" || id === null) leaf = id ?? "";
  } catch {}
  try {
    const file = ctx?.sessionManager?.getSessionFile?.();
    if (typeof file === "string") sessionFile = file;
  } catch {}
  const payload = JSON.stringify({
    hook_event_name: event,
    session_id: sessionID,
    transcript_path: sessionFile,
    ...(sessionFile && leaf !== undefined ? { transcript_leaf: leaf } : {}),
    ...extra,
  });
  // The daemon is not told again what it already has: the end of a turn, or a
  // second file event for one append, names the entry the last report named.
  // Every report that carries a selection counts, not only the metadata ones.
  const selection = sessionFile && leaf !== undefined ? sessionID + "\0" + sessionFile + "\0" + leaf : "";
  if (event === "transcript_update" && selection && selection === lastSelection) return;
  if (selection) lastSelection = selection;
  // A report that cannot be sent must never break Pi.
  enqueue(payload, event === "transcript_update" ? sessionID + "\0" + sessionFile : "");
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
  let epoch = 0;
  let watcher;

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
    // The idle CLI has no leaf field; keep v3's final transcript selection in
    // sync even when this stop intentionally does not create a done report.
    report("transcript_update", ctx, {});
    // Idle ends activity without creating a successful or errored Inbox item.
    // Do not use session_start, which would reset the session's state.
    const pane = process.env.TUIOS_PANE_ID;
    const session = process.env.TUIOS_SESSION;
    if (!pane || !session) return; // Never fall back to the focused pane.
    const args = ["set-agent-state", "idle", "--session", session,
      "--window", pane, "--harness", "pi"];
    try {
      const id = ctx?.sessionManager?.getSessionId?.();
      if (typeof id === "string" && id) args.push("--agent-session-id", id);
    } catch {}
    enqueue("", "", args);
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

  const stopWatching = () => {
    watcher?.close();
    watcher = undefined;
  };
  const startWatching = ctx => {
    const file = ctx?.sessionManager?.getSessionFile?.();
    if (typeof file !== "string" || !file) return;
    const current = epoch;
    try {
      // Pi's _appendEntry sets leafId then persists synchronously. A file
      // notification observes that actual boundary even when a later async
      // message_end extension delays persistence, or a custom message at rest
      // emits no extension event. Watch the parent so first creation/rotation
      // works too. No transcript content is ever read by this extension.
      watcher = watch(dirname(file), { persistent: false }, (_kind, name) => {
        if (tui && epoch === current && (!name || String(name) === basename(file))) {
          report("transcript_update", ctx, {});
        }
      });
      watcher.on("error", () => { if (epoch === current) stopWatching(); });
    } catch {
      // Filesystem watching is optional; lifecycle reports still work.
    }
  };
  pi.on("session_start", (_event, ctx) => {
    stopWatching();
    epoch++;
    tui = ctx?.mode === "tui";
    outcome = undefined;
    finalAnswer = false;
    retryID = undefined;
    settledCtx = undefined;
    cancelled = false;
    promptDepth = 0;
    if (!tui) return;
    startWatching(ctx);
    // A reload replaces the extension mid-turn without a new agent_start.
    report("session_start", ctx, { busy: ctx?.isIdle?.() === false });
  });
  pi.on("session_tree", (_event, ctx) => {
    if (tui) report("transcript_update", ctx, {});
  });
  pi.on("session_compact", (_event, ctx) => {
    if (tui) report("transcript_update", ctx, {});
  });
  pi.on("turn_end", (_event, ctx) => {
    if (tui) report("transcript_update", ctx, {});
  });
  pi.on("session_shutdown", () => {
    tui = false;
    epoch++;
    retryID = undefined;
    settledCtx = undefined;
    stopWatching();
    return drain();
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
}
