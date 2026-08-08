import { execFile } from "node:child_process";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);
const TERMUX_BATTERY_TIMEOUT_MS = 10_000;

type TermuxBatteryStatus = {
  percentage?: unknown;
  level?: unknown;
  status?: unknown;
  plugged?: unknown;
  temperature?: unknown;
};

type BatteryPayload = {
  battery: number;
  charging: 0 | 1;
  temperature?: number;
};

/**
 * Termux API returns Android's battery state as JSON.  Prefer `percentage`,
 * but retain `level` as a compatibility fallback for older API versions.
 */
function parseBatteryLevel(status: TermuxBatteryStatus): number {
  const rawLevel = status.percentage ?? status.level;
  const level = typeof rawLevel === "number" ? rawLevel : Number(rawLevel);
  if (!Number.isFinite(level)) {
    throw new Error(`Invalid battery percentage from termux-battery-status: ${String(rawLevel)}`);
  }

  return Math.max(0, Math.min(100, Math.round(level)));
}

/** Keep charging-state handling consistent with charge_manager.js. */
function isCharging(status: TermuxBatteryStatus): boolean {
  const batteryStatus = String(status.status ?? "").toUpperCase();
  const plugged = String(status.plugged ?? "").toUpperCase();

  if (batteryStatus === "CHARGING" || batteryStatus === "FULL") {
    return true;
  }
  // Android can report DISCHARGING briefly while AC power remains connected.
  if (batteryStatus === "DISCHARGING") {
    return plugged === "PLUGGED_AC";
  }

  // For unrecognised states, the physical connection is the best fallback.
  return plugged !== "UNPLUGGED";
}

function parseTemperature(raw: unknown): number | undefined {
  const temperature = typeof raw === "number" ? raw : Number(raw);
  // termux-battery-status reports degrees Celsius, unlike the old sysfs value
  // which was expressed in tenths of a degree.
  return Number.isFinite(temperature) ? temperature : undefined;
}

async function readBatteryStatus(): Promise<TermuxBatteryStatus> {
  const { stdout } = await execFileAsync(
    "termux-battery-status",
    [],
    { timeout: TERMUX_BATTERY_TIMEOUT_MS, maxBuffer: 64 * 1024 },
  );

  try {
    const parsed: unknown = JSON.parse(stdout);
    if (parsed === null || typeof parsed !== "object" || Array.isArray(parsed)) {
      throw new Error("result is not a JSON object");
    }
    return parsed as TermuxBatteryStatus;
  } catch (error: unknown) {
    const detail = error instanceof Error ? error.message : String(error);
    throw new Error(`Unable to parse termux-battery-status output: ${detail}`);
  }
}

function localTimestamp(): string {
  return new Date().toLocaleString();
}

async function main(): Promise<void> {
  const batteryStatus = await readBatteryStatus();
  const payload: BatteryPayload = {
    battery: parseBatteryLevel(batteryStatus),
    charging: isCharging(batteryStatus) ? 1 : 0,
  };

  const temperature = parseTemperature(batteryStatus.temperature);
  if (temperature !== undefined) {
    payload.temperature = temperature;
  }

  const host = process.env.MQTT_HOST ?? "mido.lan";
  const port = process.env.MQTT_PORT ?? "1883";
  const topic = process.env.MQTT_TOPIC ?? "device/iqoo-z1/battery";
  const qos = process.env.MQTT_QOS ?? "1";
  const message = JSON.stringify(payload);

  await execFileAsync("mosquitto_pub", [
    "-h", host,
    "-p", port,
    "-t", topic,
    "-q", qos,
    "-m", message,
  ], { timeout: 15_000 });

  console.log(`[${localTimestamp()}] Published battery telemetry to ${topic}: ${message}`);
}

main().catch((error: unknown) => {
  console.error(`[${localTimestamp()}] ${error instanceof Error ? error.stack ?? error.message : String(error)}`);
  process.exitCode = 1;
});
