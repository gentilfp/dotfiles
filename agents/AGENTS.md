# Shared agent defaults

Use RTK for supported shell commands (for example `rtk git status`). Do not
double-prefix commands already rewritten by a hook. Use `rtk proxy <command>`
when exact output is necessary or no filtered command fits. Recover full output
before making a decision from truncated results.

For indexed projects, use CodeGraph MCP or `codegraph explore` to understand
symbols and call paths before broad file reads. If no index exists, use normal
search; initialize a project with `codegraph init` when useful. Keep indexes local.

Use Zoku only for explicitly requested card work, following the requested
`zok-plan`, `zok-implement`, `zok-test`, or `zok-close` skill, or the original
`zoku` workflow.
Authentication and project permissions remain specific to each machine/harness.
