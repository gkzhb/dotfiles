// Smoke tests for the official tuios integration and the local settlement policy.
// Run: node --test .pi/agent/tests/test-tuios-agent-state.mjs
import assert from "node:assert/strict";
import { EventEmitter } from "node:events";
import { readFileSync } from "node:fs";
import { stripTypeScriptTypes } from "node:module";
import { basename, dirname } from "node:path";
import test from "node:test";
import vm from "node:vm";

const source = readFileSync(new URL("../extensions/tuios-agent-state.ts", import.meta.url), "utf8")
  .replace(/^import .*;$/gm, "")
  .replace("export default function (pi)", "function installTuios(pi)");
const policySource = stripTypeScriptTypes(readFileSync(new URL("../extensions/tuios-agent-policy.ts", import.meta.url), "utf8"))
  .replace(/^import .*;$/gm, "")
  .replace("export default function (", "function installPolicy(");

function harness({ mode = "tui", inside = true, socketError, policy = false, env = {}, idleError = false } = {}) {
  const requests = [];
  const cli = [];
  const watchers = [];
  const idle = [];
  const handlers = new Map();
  const bus = new EventEmitter();
  const state = { idle: true, leaf: "leaf-0" };
  const ctx = {
    mode,
    isIdle: () => state.idle,
    sessionManager: {
      getSessionId: () => "pi-session",
      getSessionFile: () => "/fake/transcript.jsonl",
      getLeafId: () => state.leaf,
    },
  };
  vm.runInNewContext(source + policySource + (policy ? "\ninstallPolicy(pi);" : "\ninstallTuios(pi);"), {
    Buffer, AbortController, basename, dirname, setTimeout, clearTimeout,
    process: { env: {
      ...(inside && { TUIOS_ENV: "1", TUIOS_SOCKET: "/fake/tuios.sock", TUIOS_SESSION: "session", TUIOS_PANE_ID: "pane" }),
      ...env,
    } },
    pi: {
      on(name, handler) {
        if (!handlers.has(name)) handlers.set(name, []);
        handlers.get(name).push(handler);
      },
      events: { on(name, fn) { bus.on(name, fn); return () => bus.off(name, fn); } },
      async exec(command, args) {
        idle.push([command, ...args]);
        if (idleError) throw new Error("tuios unavailable");
      },
    },
    // Exercise the shipped transports without contacting the current tuios daemon.
    tuiosConnect(path) {
      assert.equal(path, "/fake/tuios.sock");
      const socket = new EventEmitter();
      socket.setEncoding = socket.destroy = () => {};
      socket.write = text => {
        requests.push(JSON.parse(text));
        queueMicrotask(() => socket.emit("data", JSON.stringify(socketError
          ? { id: 1, error: { code: socketError } }
          : { id: 1, result: { stdout: "" } }) + "\n"));
      };
      queueMicrotask(() => socket.emit("connect"));
      return socket;
    },
    spawn(command, args) {
      const child = new EventEmitter();
      child.stdin = new EventEmitter();
      child.stdin.end = data => {
        cli.push({ command, args: [...args], payload: JSON.parse(data) });
        queueMicrotask(() => child.emit("close", 0));
      };
      return child;
    },
    readFileSync() { throw new Error("No pi-subagents config"); },
    watch(directory, options, callback) {
      const watcher = new EventEmitter();
      watcher.close = () => { watcher.closed = true; };
      Object.assign(watcher, { directory, options, callback });
      watchers.push(watcher);
      return watcher;
    },
  }, { filename: "tuios-agent-state.ts" });
  const tick = () => new Promise(resolve => setImmediate(resolve));
  return {
    state, requests, cli, watchers, bus, tick, idle,
    async emit(name, event = {}) {
      for (const handler of handlers.get(name) ?? []) await handler(event, ctx);
      await tick();
    },
    payloads: () => requests.map(request => {
      assert.equal(request.verb, "agent-hook-event");
      assert.equal(request.params.harness, "pi");
      return JSON.parse(request.params.payload);
    }),
  };
}

const names = payloads => payloads.map(payload => payload.hook_event_name);

test("official lifecycle uses the socket and reports blocking prompts and settlement", async () => {
  const h = harness();
  await h.emit("session_start");
  h.state.idle = false;
  await h.emit("agent_start");
  await h.emit("ui_prompt_start", { kind: "confirm", title: "Approve?" });
  await h.emit("ui_prompt_end", { kind: "confirm" });
  await h.emit("agent_settled"); // Not yet idle: no report.
  h.state.idle = true;
  h.state.leaf = "leaf-final";
  await h.emit("agent_settled", { aborted: true }); // The official hook does not filter aborts.
  await h.emit("session_shutdown");
  const payloads = h.payloads();
  assert.deepEqual(names(payloads), ["session_start", "agent_start", "ui_prompt_start", "ui_prompt_end", "agent_settled"]);
  assert.equal(payloads[2].title, "Approve?");
  assert.equal(payloads[3].busy, true);
  assert.equal(payloads.at(-1).transcript_leaf, "leaf-final");
  assert.equal(h.cli.length, 0);
  assert.equal(h.watchers[0].closed, true);
});

test("an older daemon falls back to the v5 CLI hook in report order", async () => {
  const h = harness({ socketError: "unknown_verb" });
  await h.emit("session_start");
  await h.emit("agent_start");
  await h.emit("agent_settled");
  await h.emit("session_shutdown");
  assert.equal(h.requests.length, 1);
  assert.deepEqual(names(h.cli.map(call => call.payload)), ["session_start", "agent_start", "agent_settled"]);
  for (const call of h.cli) {
    assert.equal(call.command, "tuios");
    assert.deepEqual(call.args, ["agent-hook", "pi", "--integration", "5"]);
  }
});

test("transcript updates report only changed selections and ignore unrelated file events", async () => {
  const h = harness();
  await h.emit("session_start");
  h.state.leaf = "leaf-1";
  h.watchers[0].callback("change", "unrelated.jsonl");
  await h.tick();
  assert.equal(h.requests.length, 1);
  h.watchers[0].callback("change", "transcript.jsonl");
  await h.emit("turn_end"); // Same leaf, not a second report.
  h.state.leaf = null;
  await h.emit("session_tree");
  await h.emit("session_shutdown");
  assert.deepEqual(names(h.payloads()), ["session_start", "transcript_update", "transcript_update"]);
  assert.deepEqual(h.payloads().map(payload => payload.transcript_leaf), ["leaf-0", "leaf-1", ""]);
});

test("pi-subagents lifecycle adds child reports without settling the parent", async () => {
  const h = harness();
  await h.emit("session_start");
  h.bus.emit("subagent:async-started", { id: "run-1", agent: "reviewer", label: "Review diff" });
  h.bus.emit("subagent:async-complete", { id: "run-1", results: [{ summary: "No findings" }] });
  await h.emit("session_shutdown");
  const payloads = h.payloads();
  assert.deepEqual(names(payloads), ["session_start", "subagent_start", "subagent_stop"]);
  assert.equal(payloads[1].agent_type, "reviewer");
  assert.equal(payloads[2].agent_id, "run-1");
  assert.equal(payloads[2].text, "No findings");
  assert.equal(h.bus.listenerCount("subagent:async-started"), 0);
});

test("non-TUI sessions and sessions outside tuios do not report", async () => {
  for (const policy of [false, true]) {
    for (const options of [{ mode: "print" }, { mode: "json" }, { mode: "rpc" }, { inside: false }]) {
      const h = harness({ policy, ...options });
      await h.emit("session_start");
      await h.emit("agent_start");
      await h.emit("agent_settled");
      await h.emit("session_shutdown");
      assert.equal(h.requests.length + h.cli.length + h.watchers.length + h.idle.length, 0);
    }
  }
});

const answer = { role: "assistant", stopReason: "stop", content: [{ type: "text", text: "Answer" }] };

async function turn(h, { messages = [answer], outcome = "completed", aborted = false } = {}) {
  h.state.idle = false;
  await h.emit("agent_start");
  await h.emit("agent_end", { messages });
  if (outcome !== null) await h.emit("agent_before_settle", { outcome });
  h.state.idle = true;
  await h.emit("agent_settled", { aborted });
}

test("wrapped success still uses the official socket, transcript and child reports", async () => {
  const h = harness({ policy: true });
  await h.emit("session_start");
  h.bus.emit("subagent:async-started", { id: "run-1", agent: "reviewer" });
  await h.emit("ui_prompt_start", { kind: "confirm" });
  await h.emit("ui_prompt_end", { kind: "confirm" });
  h.state.leaf = "answer-leaf";
  await turn(h);
  assert.deepEqual(names(h.payloads()), ["session_start", "subagent_start", "ui_prompt_start", "ui_prompt_end", "agent_start", "agent_settled"]);
  assert.equal(h.payloads().at(-1).transcript_leaf, "answer-leaf");
  assert.equal(h.idle.length + h.cli.length, 0);
  await h.emit("session_shutdown");
});

for (const [reason, result] of [
  ["failure", { outcome: "error" }],
  ["cancelled", { aborted: true, outcome: null }],
  ["abort after pre-settle", { aborted: true }],
  ["empty output", { messages: [{ ...answer, content: [{ type: "text", text: " \n " }] }] }],
  ["tool call", { messages: [{ ...answer, content: [...answer.content, { type: "toolCall" }] }] }],
  ["truncated output", { messages: [{ ...answer, stopReason: "length" }] }],
  ["no assistant reply", { messages: [{ role: "user" }] }],
  ["unknown outcome", { outcome: null }],
]) {
  test(`wrapped ${reason} never reports done and only clears a working pane`, async () => {
    const h = harness({ policy: true });
    await h.emit("session_start");
    await turn(h);
    await turn(h, result); // A prior success must not leak into the next turn.
    assert.deepEqual(names(h.payloads()), ["session_start", "agent_start", "agent_settled", "agent_start"]);
    assert.deepEqual(h.idle, [["tuios", "set-agent-state", "idle", "--session", "session", "--window", "pane",
      "--harness", "pi", "--if-state", "working", "--agent-session-id", "pi-session"]]);
    await h.emit("session_shutdown");
  });
}

test("wrapped idle never targets a focused pane by default or another harness", async () => {
  for (const env of [{ TUIOS_PANE_ID: "" }, { TUIOS_SESSION: "" }, { TUIOS_AGENT: "codex" }]) {
    const h = harness({ policy: true, env });
    await h.emit("session_start");
    await turn(h, { aborted: true });
    assert.equal(h.idle.length, 0);
    assert.ok(!names(h.payloads()).includes("agent_settled"));
    await h.emit("session_shutdown");
  }
});

test("wrapped idle reporting failure does not break settlement", async () => {
  const h = harness({ policy: true, idleError: true });
  await h.emit("session_start");
  await turn(h, { outcome: "error" });
  assert.equal(h.idle.length, 1);
  assert.ok(!names(h.payloads()).includes("agent_settled"));
  await h.emit("session_shutdown");
});
