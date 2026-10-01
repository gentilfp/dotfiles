import { homedir } from "node:os";
import { join } from "node:path";
import { existsSync } from "node:fs";
import { stripVTControlCharacters } from "node:util";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { truncateToWidth } from "@earendil-works/pi-tui";

const REFRESH_MS = 60_000;
const localAij = join(homedir(), ".local", "bin", "aij");
const aij = existsSync(localAij) ? localAij : "aij";
const clean = (text: string) => stripVTControlCharacters(text).replace(/[\x00-\x1f\x7f-\x9f]/g, " ");

type Limit = { id: string; label: string; kind: string; usedPercent: number | null; resetsAt?: string; resetsLabel?: string };
type Snapshot = { id: string; status: string; limits: Limit[]; source?: string; stale?: boolean };

export function quotaProvider(provider: string | undefined, oauth: boolean): string | undefined {
  if (provider === "anthropic" && oauth) return "claude";
  if (provider === "openai-codex" && oauth) return "codex";
  if (provider === "opencode" || provider === "opencode-go") return "opencode";
  return undefined;
}

export function parseStatus(stdout: string): Snapshot[] {
  const data = JSON.parse(stdout);
  if (!data || !Array.isArray(data.providers)) throw new Error("Invalid aij output");
  return data.providers.map((p: Snapshot) => {
    if (!p || typeof p.id !== "string" || typeof p.status !== "string" || !Array.isArray(p.limits)) {
      throw new Error("Invalid aij provider");
    }
    for (const l of p.limits) {
      if (!l || typeof l.id !== "string" || typeof l.label !== "string" || typeof l.kind !== "string"
        || (l.usedPercent !== null && (typeof l.usedPercent !== "number" || !Number.isFinite(l.usedPercent) || l.usedPercent < 0 || l.usedPercent > 100))
        || (l.resetsAt !== undefined && typeof l.resetsAt !== "string")
        || (l.resetsLabel !== undefined && typeof l.resetsLabel !== "string")) {
        throw new Error("Invalid aij limit");
      }
    }
    return p;
  });
}

export function resetText(date: string, now: number): string {
  const ms = Date.parse(date) - now;
  if (!Number.isFinite(ms)) return "reset unknown";
  if (ms <= 0) return "reset due";
  const minutes = Math.ceil(ms / 60_000);
  const hours = Math.floor(minutes / 60);
  return `resets ${hours >= 24 ? `${Math.floor(hours / 24)}d${hours % 24}h` : hours > 0 ? `${hours}h${minutes % 60}m` : `${minutes}m`}`;
}

export function usageText(snapshot: Snapshot | undefined, now: number, failed = false): string {
  if (!snapshot) return "remaining unavailable";
  if (snapshot.status !== "ok") return `remaining ${clean(snapshot.status)}`;
  const limits = snapshot.limits.map((l) => {
    const label = l.id === "five_hour" || l.id === "codex-session" ? "5h"
      : l.kind === "weekly" ? "7d" : l.kind === "monthly" ? "monthly" : clean(l.label);
    const reset = l.resetsAt ? resetText(l.resetsAt, now) : l.resetsLabel ? `resets ${clean(l.resetsLabel)}` : "";
    const remaining = l.usedPercent === null ? "?" : Math.round((100 - l.usedPercent) * 10) / 10;
    return `${label} ${remaining}%${reset ? ` (${reset})` : ""}`;
  });
  const provenance = failed || snapshot.stale ? "stale" : snapshot.source === "cached" ? "cached" : snapshot.source === "estimate" ? "estimate" : "";
  return (limits.join(" · ") || "remaining unavailable") + (provenance ? ` · ${provenance}` : "");
}

export default function (pi: ExtensionAPI) {
  let current: ExtensionContext | undefined;
  let snapshots: Snapshot[] = [];
  let failed = false;
  let loading = false;
  let lastAttempt = 0;
  let timer: ReturnType<typeof setInterval> | undefined;
  let pending: AbortController | undefined;
  let requestRender = () => {};

  const provider = () => {
    const model = current?.model;
    return quotaProvider(model?.provider, !!model && !!current?.modelRegistry.isUsingOAuth(model));
  };

  async function refresh(force = false) {
    if (!current || !provider() || pending || (!force && Date.now() - lastAttempt < REFRESH_MS)) return;
    const controller = new AbortController();
    pending = controller;
    lastAttempt = Date.now();
    loading = true;
    requestRender();
    try {
      // ai-juice CLI: `aij verbose` prints the full JSON status document ({ providers }) as stdout.
      const result = await pi.exec(aij, ["verbose"], { timeout: 30_000, signal: controller.signal });
      if (controller.signal.aborted) return;
      // aij exits 1 if ANY provider fails; other providers still have valid JSON.
      if (result.killed) throw new Error("aij timed out");
      snapshots = parseStatus(result.stdout);
      failed = false;
    } catch {
      if (!controller.signal.aborted) failed = true;
    } finally {
      if (pending === controller) {
        pending = undefined;
        loading = false;
        requestRender();
      }
    }
  }

  function stop() {
    clearInterval(timer);
    timer = undefined;
    pending?.abort();
    pending = undefined;
    current = undefined;
    requestRender = () => {};
  }

  pi.on("session_start", (_event, ctx) => {
    stop();
    if (ctx.mode !== "tui") return;
    snapshots = [];
    failed = false;
    lastAttempt = 0;
    ctx.ui.setFooter((tui, theme, footerData) => {
      current = ctx;
      requestRender = () => tui.requestRender();
      return {
        invalidate() {},
        dispose: stop,
        render(width) {
          const active = current;
          if (!active) return [];
          const home = homedir();
          const cwd = active.cwd === home ? "~" : active.cwd.startsWith(home + "/") ? "~" + active.cwd.slice(home.length) : active.cwd;
          const model = active.model;
          const thinking = pi.getThinkingLevel();
          const first = `${clean(cwd)} · ${clean(model?.provider || "?")}/${clean(model?.name || model?.id || "no model")}${thinking !== "off" ? ` (${thinking})` : ""}`;
          const id = provider();
          const snapshot = snapshots.find((p) => p.id === id);
          const second = !id ? "remaining unavailable for this provider/auth"
            : !snapshot && loading ? "loading remaining…" : usageText(snapshot, Date.now(), failed);
          const lines = [theme.fg("dim", first), theme.fg("muted", second)];
          // Keep statuses from other extensions visible instead of silently hiding them.
          const statuses = [...footerData.getExtensionStatuses().values()].join(" · ");
          if (statuses) lines.push(statuses);
          return lines.map((line) => truncateToWidth(line, width));
        },
      };
    });
    timer = setInterval(() => { requestRender(); void refresh(); }, REFRESH_MS);
    timer.unref();
    void refresh(true);
  });
  pi.on("model_select", (_event, ctx) => {
    if (!current) return;
    current = ctx;
    requestRender();
    void refresh();
  });
  pi.on("thinking_level_select", () => requestRender());
  pi.on("agent_end", () => { void refresh(); });
  pi.on("session_shutdown", stop);
  pi.registerCommand("aij-refresh", {
    description: "Refresh the AI Juice quota footer (uses the same accounts as aij).",
    handler: async () => { await refresh(true); },
  });
}
