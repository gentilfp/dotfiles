# Shared agent defaults

Apply the installed `ponytail` skill on coding tasks, at full intensity.
Understand the existing flow first. Prefer clear ownership and the simplest
complete solution. Never trade correctness, safety, accessibility, or required
behavior for fewer lines or files.

Apply the installed `caveman` skill at lite intensity: concise, readable replies.
Keep code, identifiers, errors, and persisted documentation exact. Explicit user
requests for detail win. The `talk-to-me` skill supplies the response structure;
Caveman removes filler. Do not repeat instructions or announce mode activation.

Use RTK for supported shell commands (for example `rtk git status`). Do not
double-prefix commands already rewritten by a hook. Use `rtk proxy <command>`
when exact output is necessary or no filtered command fits. Recover full output
before making a decision from truncated results.

For indexed projects, use CodeGraph MCP or `codegraph explore` to understand
symbols and call paths before broad file reads. If no index exists, use normal
search; initialize a project with `codegraph init` when useful. Keep indexes local.

Use Zoku only for explicitly requested card work, following the `zoku` skill.
Authentication and project permissions remain specific to each machine/harness.
