// Execute the real extension with temporary PATH/HOME and mocked subprocesses.
// Never run the installed TeamAI CLI, dispatch real hooks, or mutate user files.
// Run: node --test dotfiles/.pi/agent/tests/test-teamai-hooks.mjs
import assert from "node:assert/strict";
import { EventEmitter } from "node:events";
import fs from "node:fs";
import { tmpdir } from "node:os";
import { delimiter, join, resolve } from "node:path";
import test from "node:test";
import vm from "node:vm";

const source = fs.readFileSync(new URL("../extensions/teamai-hooks.ts", import.meta.url), "utf8")
  .replace(/^import .*;\n/gm, "")
  .replace("export default function teamaiHooks(pi)", "function install(pi)");
const tick = () => new Promise(resolve => setImmediate(resolve));

function fixture(t) {
  const root = fs.mkdtempSync(join(tmpdir(), "teamai-hooks-"));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const home = join(root, "user home");
  fs.mkdirSync(home);
  const bin = name => { const path = join(root, name); fs.mkdirSync(path); return path; };
  const executable = (directory, mode = 0o755) => {
    const path = join(directory, "teamai");
    fs.writeFileSync(path, "#!/bin/sh\nexit 0\n", { mode });
    return path;
  };
  return { root, home, bin, executable };
}

function harness({ home, path, hooks = {}, failure, hold = false, cwd = "/initial/cwd" }) {
  const calls = [];
  const reads = [];
  const handlers = new Map();
  const timers = new Map();
  let timerId = 0;
  const expectedHooksPath = join(home, ".teamai", "team-hooks", "pi.json");
  const sandbox = {
    delimiter, join, resolve: (...parts) => resolve(cwd, ...parts),
    homedir: () => home,
    process: { env: path === undefined ? {} : { PATH: path }, cwd: () => cwd },
    fs: {
      ...fs,
      readFileSync(path, encoding) {
        reads.push(path);
        if (path === expectedHooksPath) return JSON.stringify({ hooks });
        throw new Error("Unexpected hook file path");
      },
    },
    console: { error() {} },
    setTimeout(fn, ms) { const id = ++timerId; timers.set(id, { fn, ms }); return id; },
    clearTimeout(id) { timers.delete(id); },
    spawn(command, args, options) {
      const call = { command, args: [...args], options, killed: false };
      calls.push(call);
      if (failure === "throw") throw new Error("ENOENT");
      const child = new EventEmitter();
      child.stdin = new EventEmitter();
      child.stdout = new EventEmitter();
      child.stderr = new EventEmitter();
      child.stdin.end = data => { call.payload = JSON.parse(data); };
      child.kill = () => { call.killed = true; };
      call.child = child;
      if (!hold) queueMicrotask(() => {
        if (failure === "event") {
          child.emit("error", new Error("ENOENT"));
          child.stdin.emit("error", new Error("EPIPE"));
        } else {
          const output = args.includes("--team-hooks")
            ? args[1] === "PreToolUse" ? { block: "not allowed" } : { context: `context:${args[1]}` }
            : args[1] === "instructions" ? { hookSpecificOutput: { additionalContext: "team instructions" } } : {};
          child.stdout.emit("data", JSON.stringify(output));
        }
        child.emit("close", failure ? -1 : 0);
      });
      return child;
    },
    pi: { on(name, handler) { handlers.set(name, handler); } },
  };
  vm.runInNewContext(source + "\ninstall(pi);", sandbox, { filename: "teamai-hooks.ts" });
  const ctx = {
    cwd: "/project with spaces",
    sessionManager: { getSessionId: () => "session-id", getSessionFile: () => "/session.jsonl" },
  };
  return {
    calls, reads, handlers, ctx, timers,
    async emit(name, event = {}, context = ctx) {
      const result = await handlers.get(name)?.(event, context);
      await tick();
      return result;
    },
  };
}

test("TeamAI generator treats the customized same-name file as user-owned", () => {
  // generatedFileState/injectPiHooks checks this exact substring before rewriting.
  assert.equal(source.includes("[teamai] hooks extension"), false);
  assert.equal(source.includes("/Users/"), false);
});

for (const mode of ["unset PATH", "empty PATH", "missing", "not executable", "directory", "broken symlink"]) {
  test(`${mode}: register no handlers and start no processes`, t => {
    const f = fixture(t); const bin = f.bin("empty-bin");
    if (mode === "not executable") f.executable(bin, 0o644);
    if (mode === "directory") fs.mkdirSync(join(bin, "teamai"));
    if (mode === "broken symlink") fs.symlinkSync(join(bin, "gone"), join(bin, "teamai"));
    const h = harness({ home: f.home, path: mode === "unset PATH" ? undefined : mode === "empty PATH" ? "" : bin });
    assert.equal(h.handlers.size, 0);
    assert.equal(h.calls.length, 0);
    assert.equal(h.reads.length, 0);
    assert.equal(h.timers.size, 0);
  });
}

test("find executable after invalid candidates; registration starts no processes", t => {
  const f = fixture(t); const first = f.bin("first"); const second = f.bin("second");
  f.executable(first, 0o644); f.executable(second);
  const h = harness({ home: f.home, path: [first, second].join(delimiter) });
  assert.deepEqual([...h.handlers.keys()], ["session_start", "agent_settled", "before_agent_start", "tool_call", "tool_execution_start", "tool_execution_end"]);
  assert.equal(h.calls.length, 0);
  assert.equal(h.reads.length, 0);
});

test("PATH priority and spaces: all three spawn paths invoke the selected CLI directly", async t => {
  const f = fixture(t); const first = f.bin("first bin"); const second = f.bin("second");
  const entry = f.executable(first); f.executable(second);
  const hooks = Object.fromEntries(["SessionStart", "UserPromptSubmit", "PreToolUse", "PostToolUse", "Stop"].map(name => [name, [{}]]));
  const h = harness({ home: f.home, path: [first, second].join(delimiter), hooks });
  await h.emit("session_start");
  const reply = await h.emit("before_agent_start", { prompt: "hello", systemPrompt: "base" });
  assert.match(reply.systemPrompt, /team instructions/);
  assert.match(reply.systemPrompt, /context:SessionStart/);
  assert.match(reply.systemPrompt, /context:UserPromptSubmit/);
  const block = await h.emit("tool_call", { toolName: "read", input: { path: "file" } });
  assert.equal(block.block, true); assert.equal(block.reason, "not allowed");
  await h.emit("tool_execution_start", { toolCallId: "call", args: { path: "file" } });
  await h.emit("tool_execution_end", { toolCallId: "call", toolName: "read", result: { content: [{ type: "text", text: "result" }] }, isError: false });
  await h.emit("agent_settled");
  assert.ok(h.calls.some(call => call.args[1] === "instructions"));
  assert.ok(h.calls.some(call => call.args.includes("--team-hooks")));
  for (const call of h.calls) {
    assert.equal(call.command, entry);
    assert.equal(call.args[0], "hook-dispatch");
    assert.equal(call.options.shell, false);
    assert.equal(call.options.cwd, h.ctx.cwd);
    assert.equal(call.payload.session_id, "session-id");
  }
  assert.ok(h.reads.length > 0);
  assert.ok(h.reads.every(path => path === join(f.home, ".teamai", "team-hooks", "pi.json")));
  const post = h.calls.find(call => call.args[1] === "post-tool-use");
  assert.equal(post.payload.tool_response, "result");
  assert.equal(post.payload.tool_input.path, "file");
  assert.equal(post.payload.tool_status, "success");
  assert.equal(h.calls.find(call => call.args[1] === "stop").payload.transcript_path, "/session.jsonl");
  assert.equal(h.timers.size, 0);
});

test("npm-style executable symlink in PATH is accepted", async t => {
  const f = fixture(t); const bin = f.bin("bin"); const target = join(f.root, "teamai.js");
  fs.writeFileSync(target, "#!/usr/bin/env node\n", { mode: 0o755 });
  const entry = join(bin, "teamai"); fs.symlinkSync(target, entry);
  const h = harness({ home: f.home, path: bin });
  await h.emit("session_start");
  assert.ok(h.calls.length >= 2);
  assert.ok(h.calls.every(call => call.command === entry));
});

test("relative PATH is resolved before spawning in a different project cwd", async t => {
  const f = fixture(t); const bin = f.bin("bin"); const entry = f.executable(bin);
  const h = harness({ home: f.home, path: "bin", cwd: f.root });
  await h.emit("session_start");
  assert.ok(h.calls.length >= 2);
  assert.ok(h.calls.every(call => call.command === entry));
});

for (const failure of ["throw", "event"]) {
  test(`CLI disappears or cannot start (${failure}): handlers fail open`, async t => {
    const f = fixture(t); const bin = f.bin("bin"); f.executable(bin);
    const hooks = { PreToolUse: [{}] };
    const h = harness({ home: f.home, path: bin, hooks, failure });
    await h.emit("session_start");
    assert.equal(await h.emit("before_agent_start", { prompt: "hello", systemPrompt: "base" }), undefined);
    assert.equal(await h.emit("tool_call", { toolName: "bash", input: {} }), undefined);
    assert.equal(h.timers.size, 0);
  });
}

test("stalled CLI is terminated and does not indefinitely block the session", async t => {
  const f = fixture(t); const bin = f.bin("bin"); f.executable(bin);
  const h = harness({ home: f.home, path: bin, hold: true });
  const pending = h.emit("agent_settled");
  assert.equal(h.timers.size, 1);
  for (const { fn, ms } of [...h.timers.values()]) { assert.equal(ms, 15000); fn(); }
  await pending;
  assert.equal(h.calls[0].killed, true);
  assert.equal(h.timers.size, 0);
});
