// Isolated lifecycle tests: execute the real extension with mocked tuios/fs IO.
// No daemon, pane, model, or installed Pi packages are required.
// Run: node --test dotfiles/.pi/agent/tests/test-tuios-agent-state.mjs
import assert from "node:assert/strict";
import { EventEmitter } from "node:events";
import { readFileSync } from "node:fs";
import test from "node:test";
import vm from "node:vm";
import { basename, dirname } from "node:path";

const source = readFileSync(new URL("../extensions/tuios-agent-state.ts", import.meta.url), "utf8")
  .replace(/^import .*;\n/gm, "")
  .replace("export default function (pi)", "function install(pi)");
const tick = () => new Promise(resolve => setImmediate(resolve));

function harness({ env = {}, hold = false, spawnError = false, watchError = false } = {}) {
  const calls = [];
  const watchers = [];
  const handlers = new Map();
  const bus = new EventEmitter();
  const timers = new Map();
  let nextTimer = 0;
  const state = { idle: true, id: "pi-session", file: "/tmp/transcript.jsonl", leaf: "leaf-0" };
  const ctx = {
    mode: "tui",
    isIdle: () => state.idle,
    sessionManager: {
      getSessionId: () => state.id,
      getSessionFile: () => state.file,
      getLeafId: () => state.leaf,
    },
  };
  const sandbox = {
    Buffer, basename, dirname,
    process: { env: { TUIOS_ENV: "1", TUIOS_SESSION: "tuios-session", TUIOS_PANE_ID: "pane-id", ...env } },
    setTimeout(fn, ms) { const id = ++nextTimer; timers.set(id, { fn, ms }); return id; },
    clearTimeout(id) { timers.delete(id); },
    spawn(command, args, options) {
      if (spawnError === "throw") throw new Error("tuios unavailable");
      const child = new EventEmitter();
      const call = { command, args: [...args], options, child, payload: undefined, killed: false };
      child.stdin = options.stdio === "ignore" ? null : new EventEmitter();
      if (child.stdin) child.stdin.end = payload => { call.payload = JSON.parse(payload); };
      child.kill = () => { call.killed = true; child.emit("close", null); };
      calls.push(call);
      if (!hold) queueMicrotask(() => {
        if (spawnError === "event") {
          child.emit("error", new Error("ENOENT"));
          child.stdin?.emit("error", new Error("EPIPE"));
        }
        child.emit("close", spawnError ? -1 : 0);
      });
      return child;
    },
    watch(directory, options, callback) {
      if (watchError) throw new Error("watch unavailable");
      const watcher = new EventEmitter();
      watcher.close = () => { watcher.closed = true; };
      Object.assign(watcher, { directory, options, callback, closed: false });
      watchers.push(watcher);
      return watcher;
    },
  };
  vm.runInNewContext(source + "\ninstall(pi);", {
    ...sandbox,
    pi: {
      on(name, handler) { handlers.set(name, handler); },
      events: bus,
    },
  }, { filename: "tuios-agent-state.ts" });
  return {
    calls, watchers, state, ctx, timers,
    async emit(name, event = {}, context = ctx) {
      await handlers.get(name)?.(event, context);
      await tick();
    },
    retry(name, retryId) { bus.emit(`pi-retry:${name}`, { retryId }); },
    hooks(name) { return calls.filter(call => call.payload?.hook_event_name === name); },
    idleCalls() { return calls.filter(call => call.args[0] === "set-agent-state" && call.args[1] === "idle"); },
    async finish({ outcome = "completed", stopReason = "stop", content = [{ type: "text", text: "Answer" }], aborted = false } = {}) {
      state.idle = true;
      await this.emit("agent_end", { messages: [{ role: "assistant", stopReason, content }] });
      await this.emit("agent_before_settle", { outcome });
      await this.emit("agent_settled", { aborted });
    },
    release() { calls.at(-1)?.child.emit("close", 0); },
  };
}

async function started(options) {
  const h = harness(options);
  await h.emit("session_start");
  h.state.idle = false;
  await h.emit("agent_start");
  return h;
}

for (const [name, ending] of [
  ["error", { outcome: "error", stopReason: "error" }],
  ["empty text", { content: [{ type: "text", text: " \n " }] }],
  ["thinking only", { content: [{ type: "thinking", thinking: "Thought" }] }],
  ["tool call", { content: [{ type: "text", text: "Calling" }, { type: "toolCall", name: "bash" }] }],
  ["length stop", { stopReason: "length" }],
  ["aborted outcome", { outcome: "aborted" }],
  ["Escape after answer", { aborted: true }],
]) {
  test(`${name} settles to idle, never done/errored`, async () => {
    const h = await started();
    await h.finish(ending);
    assert.equal(h.hooks("agent_settled").length, 0);
    assert.equal(h.idleCalls().length, 1);
    assert.deepEqual(h.idleCalls()[0].args, ["set-agent-state", "idle", "--session", "tuios-session", "--window", "pane-id", "--harness", "pi", "--agent-session-id", "pi-session"]);
  });
}

test("only a nonempty completed normal answer reports done using v3 and its leaf", async () => {
  const h = await started();
  h.state.leaf = "final-leaf";
  await h.finish();
  const [done] = h.hooks("agent_settled");
  assert.ok(done);
  assert.deepEqual(done.args, ["agent-hook", "pi", "--integration", "3"]);
  assert.equal(done.payload.transcript_leaf, "final-leaf");
  assert.equal(h.idleCalls().length, 0);
});

test("pi-retry backoff stays working; stale receipts cannot finish a newer retry", async () => {
  const h = await started();
  h.retry("started", 11);
  h.retry("started", 12);
  await h.finish({ outcome: "error", stopReason: "error" });
  assert.equal(h.hooks("agent_settled").length, 0);
  assert.equal(h.idleCalls().length, 0);
  assert.equal(h.hooks("agent_start").length, 2);
  h.retry("cancelled", 11);
  await tick();
  assert.equal(h.idleCalls().length, 0);
  h.retry("cancelled", 12);
  await tick();
  assert.equal(h.idleCalls().length, 1);
  h.retry("completed", 12);
  await tick();
  assert.equal(h.idleCalls().length, 1);
});

test("successful detached retry reports done only after its own lifecycle completion", async () => {
  const h = await started();
  h.retry("started", 1);
  await h.finish({ outcome: "error", stopReason: "error" });
  h.state.idle = false;
  await h.emit("agent_start");
  await h.finish();
  assert.equal(h.hooks("agent_settled").length, 0);
  h.retry("completed", 1);
  await tick();
  assert.equal(h.hooks("agent_settled").length, 1);
  assert.equal(h.idleCalls().length, 0);
});

test("retry receipts ignore invalid IDs", async () => {
  const h = await started();
  for (const id of [undefined, "1", 1.1, NaN]) h.retry("started", id);
  await h.finish();
  assert.equal(h.hooks("agent_settled").length, 1);
});

test("nested UI prompts defer settlement until the last prompt ends", async () => {
  const h = await started();
  await h.emit("ui_prompt_start", { kind: "confirm", title: "Approve?" });
  await h.emit("ui_prompt_start", { kind: "input" });
  await h.finish();
  assert.equal(h.hooks("agent_settled").length, 0);
  await h.emit("ui_prompt_end", { kind: "input" });
  assert.equal(h.hooks("agent_settled").length, 0);
  await h.emit("ui_prompt_end", { kind: "confirm" });
  assert.equal(h.hooks("agent_settled").length, 1);
});

test("answering a prompt during retry backoff returns to working, not rest", async () => {
  const h = await started();
  h.retry("started", 9);
  await h.emit("ui_prompt_start", { kind: "confirm" });
  await h.finish({ outcome: "error", stopReason: "error" });
  await h.emit("ui_prompt_end", { kind: "confirm" });
  assert.equal(h.hooks("ui_prompt_end")[0].payload.busy, true);
  assert.equal(h.idleCalls().length, 0);
  h.retry("cancelled", 9);
  await tick();
  assert.equal(h.idleCalls().length, 1);
});

test("busy settlement is ignored, and a new run clears previous final-answer state", async () => {
  const h = await started();
  await h.emit("agent_end", { messages: [{ role: "assistant", stopReason: "stop", content: [{ type: "text", text: "Old answer" }] }] });
  await h.emit("agent_before_settle", { outcome: "completed" });
  await h.emit("agent_settled", { aborted: false });
  assert.equal(h.hooks("agent_settled").length, 0);
  await h.emit("agent_start");
  await h.emit("agent_end", { messages: [{ role: "user", content: "No assistant" }] });
  await h.emit("agent_before_settle", { outcome: "completed" });
  h.state.idle = true;
  await h.emit("agent_settled", { aborted: false });
  assert.equal(h.idleCalls().length, 1);
});

test("idle never falls back to whichever pane has focus", async () => {
  for (const env of [{ TUIOS_SESSION: "" }, { TUIOS_PANE_ID: "" }]) {
    const h = await started({ env });
    await h.finish({ outcome: "error" });
    assert.equal(h.idleCalls().length, 0);
    assert.equal(h.hooks("agent_settled").length, 0);
  }
});

test("new session clears deferred retry/prompt/answer state and closes the old watcher", async () => {
  const h = await started();
  h.retry("started", 7);
  await h.emit("ui_prompt_start", { kind: "input" });
  await h.finish({ aborted: true });
  const old = h.watchers[0];
  h.state.id = "new-session";
  h.state.leaf = "new-leaf";
  await h.emit("session_start");
  assert.equal(old.closed, true);
  const count = h.calls.length;
  old.callback("change", "transcript.jsonl");
  h.retry("completed", 7);
  await tick();
  assert.equal(h.calls.length, count);
  h.state.idle = false;
  await h.emit("agent_start");
  await h.finish();
  assert.equal(h.hooks("agent_settled").length, 1);
});

test("leaf metadata is deduplicated and updated by filesystem, tree, compact and turn events", async () => {
  const h = await started();
  const w = h.watchers[0];
  assert.equal(w.directory, "/tmp");
  assert.equal(w.options.persistent, false);
  await h.emit("turn_end");
  assert.equal(h.hooks("transcript_update").length, 0);
  h.state.leaf = "leaf-1";
  w.callback("change", "unrelated.jsonl");
  await tick();
  assert.equal(h.hooks("transcript_update").length, 0);
  w.callback("change", "transcript.jsonl");
  await tick();
  await h.emit("turn_end");
  assert.equal(h.hooks("transcript_update").length, 1);
  h.state.leaf = "leaf-2";
  await h.emit("session_tree");
  h.state.leaf = "leaf-3";
  await h.emit("session_compact");
  h.state.leaf = null;
  await h.emit("turn_end");
  assert.deepEqual(h.hooks("transcript_update").map(call => call.payload.transcript_leaf), ["leaf-1", "leaf-2", "leaf-3", ""]);
});

test("idle state is FIFO behind in-flight v3 reports; settlement still updates the final leaf", async () => {
  const h = await started({ hold: true });
  h.state.leaf = "failure-leaf";
  await h.finish({ outcome: "error" });
  assert.equal(h.calls.length, 1, "idle must not race the in-flight session_start");
  h.release(); await tick();
  assert.equal(h.calls[1].payload.hook_event_name, "agent_start");
  h.release(); await tick();
  assert.equal(h.calls[2].payload.hook_event_name, "transcript_update");
  assert.equal(h.calls[2].payload.transcript_leaf, "failure-leaf");
  h.release(); await tick();
  assert.equal(h.calls[3].args[0], "set-agent-state");
  h.release(); await h.emit("session_shutdown");
});

test("adjacent metadata reports coalesce to the latest leaf while delivery is blocked", async () => {
  const h = harness({ hold: true });
  await h.emit("session_start");
  for (let i = 1; i <= 100; i++) {
    h.state.leaf = `leaf-${i}`;
    await h.emit("turn_end");
  }
  h.release(); await tick();
  assert.equal(h.calls.length, 2);
  assert.equal(h.calls[1].payload.transcript_leaf, "leaf-100");
  h.release(); await h.emit("session_shutdown");
});

test("report queue stays bounded and preferentially drops metadata when full", async () => {
  const h = harness({ hold: true });
  await h.emit("session_start");
  h.state.leaf = "obsolete";
  await h.emit("turn_end");
  for (let i = 0; i < 40; i++) await h.emit("agent_start");
  for (let i = 0; i < 33; i++) { h.release(); await tick(); }
  assert.equal(h.calls.length, 33, "one active child plus at most 32 pending reports");
  assert.equal(h.hooks("transcript_update").length, 0);
  await h.emit("session_shutdown");
});

test("shutdown closes watchers, clears deferred settlement and bounds draining", async () => {
  const h = await started({ hold: true });
  h.retry("started", 3);
  await h.finish({ outcome: "error" });
  const shutdown = h.emit("session_shutdown");
  await tick();
  assert.equal(h.watchers[0].closed, true);
  h.retry("cancelled", 3);
  for (const timer of h.timers.values()) {
    assert.equal(timer.ms, 1000);
    timer.fn();
  }
  await shutdown;
  assert.equal(h.calls[0].killed, true);
  assert.equal(h.calls.length, 1);
  assert.equal(h.timers.size, 0);
});

test("reload session_start retains mid-turn busy status", async () => {
  const h = harness();
  h.state.idle = false;
  await h.emit("session_start");
  assert.equal(h.hooks("session_start")[0].payload.busy, true);
});

test("non-TUI sessions and non-tuios environments do not report or watch", async () => {
  for (const mode of ["print", "json", "rpc"]) {
    const h = harness();
    h.ctx.mode = mode;
    await h.emit("session_start");
    await h.emit("agent_start");
    h.retry("started", 1);
    await h.finish();
    await h.emit("ui_prompt_start");
    await h.emit("ui_prompt_end");
    await h.emit("session_shutdown");
    assert.equal(h.calls.length, 0);
    assert.equal(h.watchers.length, 0);
  }
  const h = harness({ env: { TUIOS_ENV: "", TUIOS_AGENT: "" } });
  await h.emit("session_start");
  await h.emit("agent_start");
  assert.equal(h.calls.length, 0);
});

test("missing tuios and optional filesystem watching cannot break Pi", async () => {
  const h = await started({ spawnError: "throw", watchError: true });
  await h.finish({ outcome: "error" });
  await h.emit("session_shutdown");
  assert.equal(h.calls.length, 0);
  assert.equal(h.watchers.length, 0);
});

test("asynchronous spawn/stdin errors release the FIFO and do not reject handlers", async () => {
  const h = await started({ spawnError: "event" });
  await h.finish({ outcome: "error" });
  assert.equal(h.idleCalls().length, 1);
  await h.emit("session_shutdown");
});

test("oversized reports are dropped without preventing later lifecycle delivery", async () => {
  const h = await started();
  const before = h.calls.length;
  await h.emit("ui_prompt_start", { title: "x".repeat(64 * 1024) });
  assert.equal(h.calls.length, before);
  await h.emit("ui_prompt_end");
  await h.finish();
  assert.equal(h.hooks("agent_settled").length, 1);
});

test("watcher errors close optional watching while lifecycle reports still work", async () => {
  const h = await started();
  h.watchers[0].emit("error", new Error("watch failure"));
  assert.equal(h.watchers[0].closed, true);
  await h.finish();
  assert.equal(h.hooks("agent_settled").length, 1);
  await h.emit("session_shutdown");
});
