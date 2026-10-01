# AI Juice footer

Run `/reload` in Pi to activate. The footer shows the current directory, model,
thinking level, and account quota used. Other extensions' status text is preserved
on an additional line when present.

Quota refreshes in the background every 60 seconds. `/aij-refresh` requests an
immediate refresh; AI Juice may still serve its own cache. Cached, estimated, and
stale results are labeled. No polling runs in print, JSON, or RPC mode.

Provider mapping:
- `anthropic` with OAuth: AI Juice `claude`.
- `openai-codex` with OAuth: AI Juice `codex`.
- `opencode` or `opencode-go`: AI Juice `opencode`.
- Other providers/authentication: usage unavailable.

These are the accounts authenticated in `aij`, not automatically verified against
Pi's accounts. Use the same accounts in both tools. Limits are account-wide, not
per-model or per-Pi-session. The extension does not read credentials itself.

The executable is `~/.local/bin/aij` when present, otherwise `aij` from PATH.

Run the checks with:

```sh
node ~/.pi/agent/extensions/aij-footer/test.mjs
```

To uninstall, remove `~/.pi/agent/extensions/aij-footer` and run `/reload`.

This extension lives in the dotfiles repo at `agents/statusline/pi/aij-footer`
and is symlinked into `~/.pi/agent/extensions` by `agents/sync.py`. Edit it in
the repo, then run `just agents-sync` on each machine.
