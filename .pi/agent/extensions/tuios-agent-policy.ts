// Load the generated extension here, not through Pi's autodiscovery.
import type { AgentActivityOutcome, AgentSettledEvent, ExtensionAPI, ExtensionContext, ExtensionHandler } from "@earendil-works/pi-coding-agent";
import installTuios from "./tuios-agent-state.ts";

export default function (pi: ExtensionAPI) {
  if (process.env.TUIOS_ENV !== "1" && !process.env.TUIOS_AGENT) return;

  let outcome: AgentActivityOutcome | undefined;
  let hasAnswer = false;
  function reset() {
    outcome = undefined;
    hasAnswer = false;
  }

  pi.on("session_start", reset);
  pi.on("agent_start", reset);
  pi.on("agent_end", ({ messages }) => {
    const reply = messages.findLast(message => message.role === "assistant");
    hasAnswer = reply?.stopReason === "stop" &&
      reply.content.some(part => part.type === "text" && part.text.trim() !== "") &&
      !reply.content.some(part => part.type === "toolCall");
  });
  pi.on("agent_before_settle", event => { outcome = event.outcome; });

  async function settle(upstream: ExtensionHandler<AgentSettledEvent>, event: AgentSettledEvent, ctx: ExtensionContext) {
    if (ctx.mode !== "tui" || !ctx.isIdle()) return;
    const done = !event.aborted && outcome === "completed" && hasAnswer;
    reset();
    if (done) return upstream(event, ctx);

    const { TUIOS_PANE_ID: pane, TUIOS_SESSION: session, TUIOS_AGENT: harness } = process.env;
    if (!pane || !session || (harness && harness !== "pi")) return;
    // There is no official idle-settlement event. Only clear a working pane:
    // do not dismiss an outstanding prompt or overwrite another status.
    const args = ["set-agent-state", "idle", "--session", session, "--window", pane,
      "--harness", "pi", "--if-state", "working"];
    try {
      const id = ctx.sessionManager.getSessionId();
      if (id) args.push("--agent-session-id", id);
      await pi.exec("tuios", args, { timeout: 750 });
    } catch {
      // Reporting is best-effort and must not break Pi's settlement.
    }
  }

  // Intercept only the official handler's registration. Other extensions
  // still receive Pi's original event, and every other official hook is unchanged.
  const on = new Proxy(pi.on, {
    apply(target, _receiver, [name, handler]) {
      if (name === "agent_settled") {
        return pi.on(name, (event, ctx) => settle(handler, event, ctx));
      }
      return Reflect.apply(target, pi, [name, handler]);
    },
  });
  return installTuios(new Proxy(pi, {
    get(target, key, receiver) {
      return key === "on" ? on : Reflect.get(target, key, receiver);
    },
  }));
}
