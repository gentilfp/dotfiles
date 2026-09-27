"""Run with: uv run --script agents/sync.py --help (installs parsers), then
uv run --with tomlkit==0.13.3 --with json5==0.12.1 python agents/test_sync.py
"""
import json
from pathlib import Path
import tempfile
from unittest.mock import patch

import sync


def put(home, name, text):
    path = home / name
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)
    return path


def acceptance():
    with tempfile.TemporaryDirectory() as temporary:
        home = Path(temporary).resolve()
        cfg = home / ".config"
        codex = put(home, ".codex/config.toml", '''# keep this comment
model = "keep-model"
[mcp_servers.zoku]
url = "https://old.invalid"
[mcp_servers.zoku.tools.move_card]
approval_mode = "approve"
[mcp_servers.other]
command = "keep-me"
''')
        claude = put(home, ".claude.json", json.dumps({
            "oauthAccount": {"test": "local-only"},
            "mcpServers": {"zoku": {"url": "old", "headers": {"X-Test": "local-only"}}}
        }))
        put(home, ".pi/agent/settings.json", '{"packages":["npm:other"],"theme":"dark"}')
        opencode = put(home, ".config/opencode/opencode.jsonc", '''{
          // a valid JSONC input
          "model": "keep-model", "mcp": {"zoku": {
            "type": "remote", "url": "old", "enabled": false,
            "oauth": {"clientId": "keep-client"}
          }}
        }''')
        instructions = put(home, ".codex/AGENTS.md", "Personal instructions.\n")
        skill = put(home, ".claude/skills/zoku/local.txt", "preserve original skill")
        old_skill_dir = skill.parent
        old_link = home / ".agents/skills/zoku"
        old_link.parent.mkdir(parents=True)
        old_link.symlink_to(home / "missing-old-ai-skills/zoku")
        plan = sync.build_plan(home, cfg, 1)
        assert codex.read_text().startswith("# keep this comment")
        plan.apply(home)
        assert not sync.build_plan(home, cfg, 1).changes, "Repeated sync must be a no-op"
        parsed = sync.tomlkit.parse(codex.read_text())
        assert parsed["model"] == "keep-model"
        assert parsed["mcp_servers"]["zoku"]["tools"]["move_card"]["approval_mode"] == "approve"
        assert parsed["mcp_servers"]["other"]["command"] == "keep-me"
        assert "# keep this comment" in codex.read_text()
        assert sync.read_json(claude)["oauthAccount"]["test"] == "local-only"
        assert sync.read_json(claude)["mcpServers"]["zoku"]["headers"]["X-Test"] == "local-only"
        assert instructions.read_text().startswith("Personal instructions.")
        assert old_link.resolve() == sync.ROOT / "skills/zoku"
        assert old_skill_dir.is_symlink()
        manifests = list((home / ".local/state/dotfiles-agents/backups").glob("*/manifest.json"))
        entries = json.loads(manifests[0].read_text())
        saved = next(Path(x["backup"]) for x in entries if x["path"] == str(old_skill_dir))
        assert (saved / "local.txt").read_text() == "preserve original skill"
        # v1 -> v2: preserve disabled state and OAuth client identity.
        sync.build_plan(home, cfg, 2).apply(home)
        v2 = sync.read_json(opencode)["mcp"]
        assert "zoku" not in v2
        assert v2["servers"]["zoku"]["disabled"] is True
        assert v2["servers"]["zoku"]["oauth"]["client_id"] == "keep-client"
        assert "enabled" not in v2["servers"]["zoku"]
        assert v2["servers"]["codegraph"]["command"] == ["codegraph", "serve", "--mcp"]
        assert not sync.build_plan(home, cfg, 2).changes

        # Concurrent local edits are never overwritten.
        plan = sync.Plan()
        plan.file(instructions, "replacement")
        instructions.write_text("concurrent edit")
        try:
            plan.apply(home)
            raise AssertionError("Concurrent change should fail")
        except RuntimeError:
            pass
        assert instructions.read_text() == "concurrent edit"

        # A failed write rolls back already-written files.
        one = put(home, "one", "original one")
        two = put(home, "two", "original two")
        plan = sync.Plan()
        plan.file(one, "new one")
        plan.file(two, "new two")
        replace = sync.os.replace
        def fail_second(source, target):
            if target == two:
                raise OSError("simulated disk failure")
            return replace(source, target)
        with patch.object(sync.os, "replace", side_effect=fail_second):
            try:
                plan.apply(home)
                raise AssertionError("Write should fail")
            except OSError:
                pass
        assert one.read_text() == "original one" and two.read_text() == "original two"
        # Bad input is rejected while still building the plan, before any write.
        opencode.write_text("{ invalid json")
        try:
            sync.build_plan(home, cfg, 2)
            raise AssertionError("Malformed JSON must fail")
        except ValueError:
            pass
    print("PASS: preservation, idempotency, backups, both OpenCode formats, concurrency, rollback, malformed input")


if __name__ == "__main__":
    acceptance()
