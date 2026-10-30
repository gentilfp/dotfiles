/**
 * MOSS pill footer for pi. Same look as zsh/moss-prompt.zsh and
 * agents/statusbar/claude-statusline.sh: directory and git pills with rounded
 * caps, then model and token usage as quiet text. Always on.
 */
import type { AssistantMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";
import { homedir } from "node:os";

const hex = (h: string) => [1, 3, 5].map((i) => parseInt(h.slice(i, i + 2), 16)).join(";");
const fg = (h: string) => `\x1b[38;2;${hex(h)}m`;
const bg = (h: string) => `\x1b[48;2;${hex(h)}m`;
const R = "\x1b[0m";
const C = { surface: "#161914", raised: "#1F231C", muted: "#70766B", faint: "#4B5147", moss: "#7E9273", ochre: "#B69A64" };
const fmt = (n: number) => (n < 1000 ? `${n}` : `${(n / 1000).toFixed(1)}k`);

export default function (pi: ExtensionAPI) {
	pi.on("session_start", (_event, ctx) => {
		ctx.ui.setFooter((tui, _theme, footerData) => {
			const unsub = footerData.onBranchChange(() => tui.requestRender());
			return {
				dispose: unsub,
				invalidate() {},
				render(width: number): string[] {
					let input = 0, output = 0;
					for (const e of ctx.sessionManager.getBranch()) {
						if (e.type === "message" && e.message.role === "assistant") {
							const m = e.message as AssistantMessage;
							input += m.usage.input;
							output += m.usage.output;
						}
					}
					const cwd = ctx.cwd.startsWith(homedir()) ? "~" + ctx.cwd.slice(homedir().length) : ctx.cwd;
					const i = cwd.lastIndexOf("/");
					const parent = i > 0 ? cwd.slice(0, i + 1) : "";
					const anchor = i > 0 ? cwd.slice(i + 1) : cwd;
					let out = `${fg(C.surface)}${R}${bg(C.surface)}${fg(C.faint)}${parent}\x1b[1m${fg(C.moss)}${anchor}\x1b[22m `;
					const branch = footerData.getGitBranch();
					if (branch) {
						out += `${R}${fg(C.surface)}${bg(C.raised)}${fg(C.moss)}  ${branch} ${R}${fg(C.raised)}${R}`;
					} else {
						out += `${R}${fg(C.surface)}${R}`;
					}
					out += `  ${fg(C.muted)}${ctx.model?.id ?? "no-model"}  ↑${fmt(input)} ↓${fmt(output)}${R}`;
					return [truncateToWidth(out, width)];
				},
			};
		});
	});
}
