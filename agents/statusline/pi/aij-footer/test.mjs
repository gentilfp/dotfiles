// Run: node ~/.pi/agent/extensions/aij-footer/test.mjs
import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { realpathSync } from "node:fs";
import { createRequire } from "node:module";
import { fileURLToPath } from "node:url";

// Reuse Pi's installed TypeScript loader and TUI; no test dependencies to install.
const requirePi = createRequire(realpathSync(execFileSync("which", ["pi"], { encoding: "utf8" }).trim()));
const { createJiti } = requirePi("jiti");
const jiti = createJiti(import.meta.url, { alias: { "@earendil-works/pi-tui": requirePi.resolve("@earendil-works/pi-tui") } });
const { default: extension, quotaProvider, parseStatus, resetText, usageText } = await jiti.import(fileURLToPath(new URL("./index.ts", import.meta.url)));
const { visibleWidth } = await jiti.import(requirePi.resolve("@earendil-works/pi-tui"));
const now = Date.parse("2026-09-09T10:00:00Z");
const payload = { providers: [
  { id: "claude", status: "ok", limits: [
    { id: "five_hour", label: "Session", kind: "session", usedPercent: 25, resetsAt: "2026-09-09T13:51:00Z" },
    { id: "seven_day", label: "Weekly", kind: "weekly", usedPercent: 66, resetsAt: "2026-09-10T18:00:00Z" },
  ] },
  { id: "codex", status: "auth-expired", limits: [] },
  { id: "opencode", status: "ok", limits: [{ id: "monthly", label: "Monthly", kind: "monthly", usedPercent: 69 }] },
] };
assert.equal(quotaProvider("anthropic", true), "claude");
assert.equal(quotaProvider("anthropic", false), undefined);
assert.equal(quotaProvider("openai-codex", true), "codex");
assert.equal(quotaProvider("openai", false), undefined);
assert.equal(quotaProvider("opencode-go", false), "opencode");
assert.equal(quotaProvider("opencode", false), "opencode");
assert.equal(quotaProvider("openrouter", true), undefined);
const snapshots = parseStatus(JSON.stringify(payload));
assert.equal(usageText(snapshots[0], now), "5h 75% (resets 3h51m) · 7d 34% (resets 1d8h)");
assert.match(usageText(snapshots[0], now, true), /stale$/);
assert.match(usageText({ ...snapshots[0], source: "cached" }, now), /cached$/);
assert.equal(usageText(snapshots[1], now), "remaining auth-expired");
assert.equal(resetText("bad", now), "reset unknown");
assert.equal(resetText("2026-09-09T09:00:00Z", now), "reset due");
assert.equal(resetText("2026-09-09T10:00:01Z", now), "resets 1m");
assert.throws(() => parseStatus("{}"));
assert.throws(() => parseStatus('{"providers":[null]}'));
assert.throws(() => parseStatus(JSON.stringify({ providers: [{ ...snapshots[0], limits: [{ ...snapshots[0].limits[0], usedPercent: 101 }] }] })));
assert.equal(usageText({ id: "test", status: "ok", limits: [{ id: "x", kind: "other", label: "\x1b[31mTest\n", usedPercent: null }] }, now), "Test  ?%");

const events = new Map();
let footer;
let calls = 0;
let mode = "success";
let abortSignal;
let thinking = "high";
const theme = { fg: (_color, text) => text };
const ctx = {
  mode: "tui", cwd: "/tmp/项目", model: { provider: "anthropic", name: "Sonnet", id: "sonnet" },
  modelRegistry: { isUsingOAuth: () => true },
  ui: { setFooter: (factory) => {
    footer?.dispose();
    footer = factory({ requestRender() {} }, theme, { getExtensionStatuses: () => new Map([["other", "existing status"]]) });
  } },
};
const commands = new Map();
extension({
  on: (name, handler) => events.set(name, handler),
  registerCommand: (name, command) => commands.set(name, command),
  getThinkingLevel: () => thinking,
  exec: async (_command, args, options) => {
    assert.deepEqual(args, ["verbose"]); // ai-juice CLI: aij verbose = full JSON status document
    calls++;
    if (mode === "failure") throw new Error("offline");
    if (mode === "pending") {
      abortSignal = options.signal;
      return new Promise((resolve) => options.signal.addEventListener("abort", () => resolve({ stdout: "", killed: true })));
    }
    // An unrelated provider failure must not hide the selected provider's quota.
    return { stdout: JSON.stringify(payload), code: 1, killed: false };
  },
});
const tick = () => new Promise((resolve) => setImmediate(resolve));
events.get("session_start")({}, ctx);
await tick();
assert.equal(calls, 1);
assert.match(footer.render(200)[0], /Sonnet \(high\)/);
assert.match(footer.render(200)[1], /5h 75%/);
assert.equal(footer.render(200)[2], "existing status");
for (const width of [0, 1, 8, 40]) assert(footer.render(width).every((line) => visibleWidth(line) <= width));
ctx.model = { provider: "opencode-go", name: "Other model" };
events.get("model_select")({}, ctx);
assert.match(footer.render(200)[1], /monthly 31%/);
assert.equal(calls, 1); // Switching providers uses the cached all-provider response.
thinking = "off";
events.get("thinking_level_select")();
assert(!footer.render(200)[0].includes("(off)"));
mode = "failure";
await commands.get("aij-refresh").handler();
assert.match(footer.render(200)[1], /stale$/);
ctx.model = { provider: "openrouter", name: "Claude through OpenRouter" };
events.get("model_select")({}, ctx);
assert.match(footer.render(200)[1], /unavailable/);
ctx.model = { provider: "opencode-go", name: "Other model" };
events.get("model_select")({}, ctx);
mode = "pending";
const refresh = commands.get("aij-refresh").handler();
const before = calls;
await commands.get("aij-refresh").handler();
assert.equal(calls, before); // No overlapping subprocesses.
events.get("session_shutdown")();
assert(abortSignal.aborted);
await refresh;
mode = "success";
events.get("session_start")({}, ctx);
await tick();
assert.match(footer.render(200)[1], /monthly 31%/); // Replacement disposes the old footer first.
assert.equal(calls, before + 1);
events.get("session_shutdown")();
events.get("session_start")({}, { ...ctx, mode: "print" });
assert.equal(calls, before + 1); // No polling outside the TUI.
console.log("PASS: quota mapping, validation, formatting, width, switching, partial failures, stale data, cancellation, headless mode");
