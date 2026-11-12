// User-managed TeamAI bridge with portable, optional CLI loading.
// No generated ownership marker: TeamAI sync must preserve this custom file.
//
// Bridges Pi extension events to the shared teamai hook-dispatch entry
// point. The child process receives the same JSON payload as shell-based hooks
// (cwd / session_id / tool_name / tool_input / prompt, and on post-tool-use the
// tool's text output and status). Errors and timeouts are swallowed so a
// missing teamai binary never blocks the Pi session. The team's hooks run only
// on the events the team has one on: a PreToolUse hook can block a tool call.

import { spawn } from "node:child_process";
import fs from "node:fs";
import { homedir } from "node:os";
import { delimiter, join, resolve } from "node:path";

// Resolve once per extension load, without starting a process. Follow executable
// symlinks (npm/Nix wrappers), skip invalid PATH entries and preserve PATH order.
function findTeamai() {
  for (const directory of (process.env.PATH ?? "").split(delimiter).filter(Boolean)) {
    const candidate = resolve(directory, "teamai");
    try {
      if (!fs.statSync(candidate).isFile()) continue;
      fs.accessSync(candidate, fs.constants.X_OK);
      return candidate;
    } catch {
      // Missing, inaccessible or broken links are not an installed CLI.
    }
  }
  return undefined;
}
/** Pi waits for a handler with no limit; the team hooks keep their own timeouts, this bounds the dispatch. */
const TEAM_HOOKS_TIMEOUT_MS = 600000;

/** The host session id (Pi's bash tool exports it as PI_SESSION_ID), read defensively. */
const sessionOf = (ctx) => {
  try {
    const id = ctx && ctx.sessionManager && ctx.sessionManager.getSessionId();
    return typeof id === "string" && id ? { session_id: id } : {};
  } catch {
    return {};
  }
};

/** The session file, as `transcript_path`, for the stop dispatch; empty when Pi keeps the session in memory only. */
const transcriptOf = (ctx) => {
  try {
    const file = ctx && ctx.sessionManager && ctx.sessionManager.getSessionFile && ctx.sessionManager.getSessionFile();
    return typeof file === "string" && file ? { transcript_path: file } : {};
  } catch {
    return {};
  }
};

/** A tool result's text parts, joined; undefined when it has no content list. */
const textOf = (content) => Array.isArray(content)
  ? content.filter((part) => part && part.type === "text" && typeof part.text === "string").map((part) => part.text).join("\n")
  : undefined;

/** @param {any} pi Pi ExtensionAPI */
export default function teamaiHooks(pi) {
  const entry = findTeamai();
  if (!entry) return;
  const teamHooksFile = join(homedir(), ".teamai", "team-hooks", "pi.json");
  const toolInputs = new Map();
  const dispatch = async (event, ctx, payload) => {
    try {
      const cwd = ctx.cwd;
      const args = ["hook-dispatch", event, "--tool", "pi"];
      const child = spawn(entry, args, {
        cwd,
        stdio: ["pipe", "ignore", "ignore"],
        windowsHide: true,
        shell: false,
      });
      const stdin = JSON.stringify({ cwd, ...sessionOf(ctx), ...(payload || {}) });
      child.stdin?.on("error", () => {});
      child.stdin?.end(stdin);
      await new Promise((resolve) => {
        let settled = false;
        const finish = () => {
          if (settled) return;
          settled = true;
          clearTimeout(timer);
          resolve(undefined);
        };
        const timer = setTimeout(() => {
          try { child.kill(); } catch {}
          finish();
        }, 15000);
        child.once("close", finish);
        child.once("error", finish);
      });
    } catch {
      // never block the agent
    }
  };

  // The member's culture, claudemd and recall blocks for a project session,
  // or "" (user scope, or teamai unavailable). Fetched once per session.
  let instructions;
  const loadInstructions = (ctx) => new Promise((resolve) => {
    try {
      const cwd = ctx.cwd;
      const child = spawn(entry, ["hook-dispatch", "instructions", "--tool", "pi"], {
        cwd,
        stdio: ["pipe", "pipe", "ignore"],
        windowsHide: true,
        shell: false,
      });
      let out = "";
      const finish = () => {
        clearTimeout(timer);
        try {
          const text = out.trim() ? JSON.parse(out).hookSpecificOutput?.additionalContext : undefined;
          resolve(typeof text === "string" ? text : "");
        } catch {
          resolve("");
        }
      };
      const timer = setTimeout(() => {
        try { child.kill(); } catch {}
        out = "";
        finish();
      }, 15000);
      child.stdout?.on("data", (chunk) => { out += chunk; });
      child.stdin?.on("error", () => {});
      child.stdin?.end(JSON.stringify({ cwd, ...sessionOf(ctx) }));
      child.once("close", finish);
      child.once("error", () => { out = ""; finish(); });
    } catch {
      resolve("");
    }
  });

  // The team's hooks for a Claude event (hooks/hooks.yaml), run by
  // `teamai hook-dispatch <Event> --tool pi --team-hooks` when the team has
  // one on it: {block} for a PreToolUse hook that refuses, {context} for what
  // a SessionStart or UserPromptSubmit hook adds, else undefined. What a hook
  // that failed or timed out wrote on stderr goes to Pi's console. Never
  // rejects: Pi blocks a tool call whose handler throws.
  const teamHooks = (event, ctx, payload) => new Promise((resolve) => {
    try {
      const hooks = JSON.parse(fs.readFileSync(teamHooksFile, "utf8")).hooks;
      if (!hooks || !Array.isArray(hooks[event]) || hooks[event].length === 0) return resolve(undefined);
      const cwd = ctx.cwd;
      const child = spawn(entry, ["hook-dispatch", event, "--tool", "pi", "--team-hooks"], {
        cwd,
        stdio: ["pipe", "pipe", "pipe"],
        windowsHide: true,
        shell: false,
      });
      let out = "";
      let err = "";
      const finish = () => {
        clearTimeout(timer);
        if (err.trim()) console.error(err.trimEnd());
        err = "";
        try {
          resolve(out.trim() ? JSON.parse(out) : undefined);
        } catch {
          resolve(undefined);
        }
      };
      const timer = setTimeout(() => {
        try { child.kill(); } catch {}
        out = "";
        finish();
      }, TEAM_HOOKS_TIMEOUT_MS);
      child.stdout?.on("data", (chunk) => { out += chunk; });
      child.stderr?.on("data", (chunk) => { err += chunk; });
      child.stdin?.on("error", () => {});
      child.stdin?.end(JSON.stringify({ cwd, ...sessionOf(ctx), ...(payload || {}) }));
      child.once("close", finish);
      child.once("error", () => { out = ""; finish(); });
    } catch {
      resolve(undefined);
    }
  });

  // What the team's SessionStart hooks added at the session's start, for its first run.
  let started;

  pi.on("session_start", async (_event, ctx) => {
    await dispatch("session-start", ctx);
    instructions = loadInstructions(ctx);
    started = teamHooks("SessionStart", ctx);
  });

  pi.on("agent_settled", async (_event, ctx) => {
    await dispatch("stop", ctx, transcriptOf(ctx));
    await teamHooks("Stop", ctx);
  });

  // Pi renders the system prompt again for every run, so adding the blocks
  // to this run's prompt reaches the model once, without piling up. For the
  // same reason the SessionStart hooks run again each run after the first:
  // what they print follows what a prompt hook changed (#1492).
  pi.on("before_agent_start", async (event, ctx) => {
    const session = started ?? teamHooks("SessionStart", ctx);
    started = undefined;
    await dispatch("prompt-submit", ctx, { prompt: event.prompt });
    const text = await (instructions ??= loadInstructions(ctx));
    // A run an extension starts (messageType "custom") carries no user prompt.
    const prompt = typeof event.prompt === "string" ? await teamHooks("UserPromptSubmit", ctx, { prompt: event.prompt }) : undefined;
    const added = [text, (await session)?.context, prompt?.context].filter((part) => typeof part === "string" && part);
    return added.length ? { systemPrompt: [event.systemPrompt, ...added].join("\n\n") } : undefined;
  });

  // Fires before the tool runs, unlike tool_execution_start, and a {block} result stops it.
  pi.on("tool_call", async (event, ctx) => {
    const decision = await teamHooks("PreToolUse", ctx, { tool_name: event.toolName, tool_input: event.input });
    return decision && typeof decision.block === "string" ? { block: true, reason: decision.block } : undefined;
  });

  pi.on("tool_execution_start", async (event) => {
    toolInputs.set(event.toolCallId, event.args);
  });

  // The result is what the model saw; isError is set for a failed call,
  // including a bash command that exits non-zero.
  pi.on("tool_execution_end", async (event, ctx) => {
    const payload = {
      tool_name: event.toolName,
      tool_input: toolInputs.get(event.toolCallId) || {},
      tool_response: textOf(event.result && event.result.content),
      tool_status: event.isError === true ? "failure" : event.isError === false ? "success" : "unknown",
    };
    toolInputs.delete(event.toolCallId);
    await dispatch("post-tool-use", ctx, payload);
    await teamHooks("PostToolUse", ctx, payload);
  });
}
