#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["tomlkit==0.13.3", "json5==0.12.1"]
# ///
"""Merge shared agent settings without copying credentials into dotfiles."""
import argparse
import fcntl
import fnmatch
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import time

import json5
import tomlkit

ROOT = Path(__file__).resolve().parent
START = "<!-- dotfiles-agents:start -->"
END = "<!-- dotfiles-agents:end -->"


def read_json(path):
    return json5.loads(path.read_text(), allow_duplicate_keys=False) if path.exists() else {}


def merge_owned(current, desired):
    """Retain local auth/approval settings; replace only shared transport fields."""
    result = dict(current)
    for key in ("type", "url", "command", "args"):
        result.pop(key, None)
    result.update(desired)
    return result


def fingerprint(path):
    if path.is_symlink():
        return ("link", os.readlink(path))
    if path.is_file():
        return ("file", path.read_bytes())
    if path.exists():
        return ("directory", path.stat().st_mtime_ns)
    return ("absent",)


class Plan:
    def __init__(self):
        self.changes = []

    def file(self, path, content):
        path = path.resolve()
        before = fingerprint(path)
        if before == ("file", content.encode()):
            return
        if before[0] not in ("file", "absent"):
            raise ValueError(f"Expected a file: {path}")
        self.changes.append((path, before, "file", content))

    def json(self, path, content):
        # Leave comments/formatting untouched when values already match.
        if path.exists() and read_json(path) == content:
            return
        self.file(path, json.dumps(content, indent=2, ensure_ascii=False) + "\n")

    def link(self, path, source):
        before = fingerprint(path)
        if before == ("link", str(source)):
            return
        self.changes.append((path, before, "link", str(source)))

    def remove(self, path):
        self.changes.append((path, fingerprint(path), "remove", None))

    def apply(self, home):
        for path, before, _, _ in self.changes:
            if fingerprint(path) != before:
                raise RuntimeError(f"Changed during planning; retry: {path}")
        if not self.changes:
            return
        backup = home / ".local/state/dotfiles-agents/backups" / str(time.time_ns())
        backup.mkdir(parents=True, mode=0o700)
        completed = []
        try:
            for index, (path, before, kind, content) in enumerate(self.changes):
                if fingerprint(path) != before:
                    raise RuntimeError(f"Changed during apply; retry: {path}")
                path.parent.mkdir(parents=True, exist_ok=True)
                saved = backup / str(index)
                if before[0] != "absent":
                    if path.is_symlink():
                        saved.symlink_to(os.readlink(path))
                    elif path.is_dir():
                        shutil.copytree(path, saved, symlinks=True)
                    else:
                        shutil.copy2(path, saved)
                        saved.chmod(0o600)
                completed.append((path, saved, before[0]))
                if kind in ("link", "remove"):
                    if path.is_dir() and not path.is_symlink():
                        shutil.rmtree(path)
                    elif path.exists() or path.is_symlink():
                        path.unlink()
                    if kind == "link":
                        path.symlink_to(content)
                else:
                    fd, temporary = tempfile.mkstemp(dir=path.parent)
                    try:
                        with os.fdopen(fd, "w") as stream:
                            stream.write(content)
                        os.replace(temporary, path)
                    finally:
                        if os.path.exists(temporary):
                            os.unlink(temporary)
            (backup / "manifest.json").write_text(json.dumps([
                {"path": str(p), "backup": str(s), "previous": k}
                for p, s, k in completed
            ], indent=2) + "\n")
        except Exception:
            for path, saved, previous in reversed(completed):
                if path.is_dir() and not path.is_symlink():
                    shutil.rmtree(path)
                elif path.exists() or path.is_symlink():
                    path.unlink()
                if previous != "absent":
                    shutil.move(str(saved), str(path))
            raise
        print(f"Backups: {backup}")


def build_plan(home, config_home, opencode_major, exclude=()):
    plan = Plan()
    servers = read_json(ROOT / "config/mcp.json")["mcpServers"]
    all_skills = sorted(p for p in (ROOT / "skills").iterdir() if (p / "SKILL.md").exists())
    skipped = [p for p in all_skills if any(fnmatch.fnmatch(p.name, g) for g in exclude)]
    skills = [p for p in all_skills if p not in skipped]
    for target in (home / ".agents/skills", home / ".claude/skills",
                   home / ".pi/agent/skills", config_home / "opencode/skills"):
        for skill in skills:
            plan.link(target / skill.name, skill)
        # Unlink excluded skills, but only links that point into this repo.
        for skill in skipped:
            path = target / skill.name
            if path.is_symlink() and path.readlink() == skill:
                plan.remove(path)

    # The old Bash array accidentally created ~/.claude/skills, (with a comma).
    # Remove only links demonstrably owned by the previous dotfiles linker.
    legacy = home / ".claude/skills,"
    for skill in skills:
        path = legacy / skill.name
        old_source = ROOT.parent / "ai-skills" / skill.name
        if path.is_symlink() and path.readlink() == old_source:
            plan.remove(path)

    instructions = (ROOT / "AGENTS.md").read_text().rstrip()
    for path in (home / ".codex/AGENTS.md", home / ".claude/CLAUDE.md",
                 home / ".pi/agent/AGENTS.md", config_home / "opencode/AGENTS.md"):
        old = path.read_text() if path.exists() else ""
        if old.count(START) != old.count(END) or old.count(START) > 1:
            raise ValueError(f"Broken managed instruction markers: {path}")
        block = f"{START}\n{instructions}\n{END}"
        if START in old:
            updated = re.sub(re.escape(START) + r".*?" + re.escape(END),
                             lambda _: block, old, flags=re.S)
        else:
            updated = old.rstrip() + ("\n\n" if old.strip() else "") + block + "\n"
        plan.file(path, updated)

    # Shared MCP source; Pi adapter uses its own OAuth credential store.
    pi_path = home / ".pi/agent/mcp.json"
    pi = read_json(pi_path)
    for name, server in servers.items():
        desired = {k: v for k, v in server.items() if k != "type"}
        current = pi.setdefault("mcpServers", {}).get(name, {})
        if server["type"] == "http":
            desired["auth"] = current.get("auth", "oauth")
        pi["mcpServers"][name] = merge_owned(current, desired)
    plan.json(pi_path, pi)
    pi_settings_path = home / ".pi/agent/settings.json"
    pi_settings = read_json(pi_settings_path)
    packages = pi_settings.setdefault("packages", [])
    if not any((p if isinstance(p, str) else p.get("source", "")).startswith("npm:pi-mcp-adapter") for p in packages):
        packages.append("npm:pi-mcp-adapter@2.37.0")
    plan.json(pi_settings_path, pi_settings)

    claude_path = home / ".claude.json"
    claude = read_json(claude_path)
    for name, server in servers.items():
        current = claude.setdefault("mcpServers", {}).get(name, {})
        claude["mcpServers"][name] = merge_owned(current, server)
    plan.json(claude_path, claude)

    codex_path = home / ".codex/config.toml"
    codex = tomlkit.parse(codex_path.read_text()) if codex_path.exists() else tomlkit.document()
    if "mcp_servers" not in codex:
        codex["mcp_servers"] = tomlkit.table()
    for name, server in servers.items():
        if name not in codex["mcp_servers"]:
            codex["mcp_servers"][name] = tomlkit.table()
        entry = codex["mcp_servers"][name]
        desired = {k: v for k, v in server.items() if k != "type"}
        for key in ("url", "command", "args"):
            if key in entry and key not in desired:
                del entry[key]
        entry.update(desired)
    plan.file(codex_path, tomlkit.dumps(codex))

    candidates = [config_home / "opencode" / name for name in ("opencode.json", "opencode.jsonc")]
    existing = [p for p in candidates if p.exists()]
    if len(existing) > 1:
        raise ValueError("Both opencode.json and opencode.jsonc exist; consolidate them before syncing")
    opencode_path = existing[0] if existing else candidates[0]
    opencode = read_json(opencode_path)
    mcp = opencode.setdefault("mcp", {})
    if opencode_major == 2:
        unknown = set(mcp) - {"servers", "timeout", *servers}
        if unknown:
            raise ValueError("Migrate other OpenCode 1 MCP entries with OpenCode first: " + ", ".join(sorted(unknown)))
        target = mcp.setdefault("servers", {})
    else:
        if "servers" in mcp:
            raise ValueError("OpenCode 2 config found with OpenCode 1 selected")
        target = mcp
    for name, server in servers.items():
        desired = ({"type": "remote", "url": server["url"]} if server["type"] == "http"
                   else {"type": "local", "command": [server["command"], *server.get("args", [])]})
        if opencode_major == 2:
            legacy = mcp.pop(name, {})
        else:
            legacy = {}
        target[name] = merge_owned(target.get(name, legacy), desired)
        if opencode_major == 2:
            entry = target[name]
            if "enabled" in entry:
                entry["disabled"] = not entry.pop("enabled")
            if isinstance(entry.get("timeout"), (int, float)):
                entry["timeout"] = {"startup": entry["timeout"]}
            if isinstance(entry.get("oauth"), dict):
                for old, new in (("clientId", "client_id"), ("clientSecret", "client_secret")):
                    if old in entry["oauth"]:
                        entry["oauth"][new] = entry["oauth"].pop(old)
    plan.json(opencode_path, opencode)

    rtk_home = (home / "Library/Application Support/rtk" if sys.platform == "darwin"
                else config_home / "rtk")
    rtk_path = rtk_home / "config.toml"
    rtk = tomlkit.parse(rtk_path.read_text()) if rtk_path.exists() else tomlkit.document()
    shared = tomlkit.parse((ROOT / "config/rtk.toml").read_text())
    for section, values in shared.items():
        if section not in rtk:
            rtk[section] = tomlkit.table()
        rtk[section].update(values)
    plan.file(rtk_path, tomlkit.dumps(rtk))
    return plan


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--apply", action="store_true")
    mode.add_argument("--check", action="store_true")
    parser.add_argument("--home", type=Path, default=Path.home(), help="alternate home for testing")
    parser.add_argument("--exclude", action="append", default=[], metavar="GLOB",
                        help="skip skills matching GLOB and unlink them if linked; repeatable")
    parser.add_argument("--opencode-major", type=int, choices=(1, 2))
    args = parser.parse_args()
    home = args.home.expanduser().resolve()
    config_home = Path(os.environ.get("XDG_CONFIG_HOME", str(home / ".config")))
    if home != Path.home():
        config_home = home / ".config"
    major = args.opencode_major
    if major is None:
        binary = shutil.which("opencode")
        if not binary:
            parser.error("Install OpenCode or specify --opencode-major 1 or 2")
        version = subprocess.check_output([binary, "--version"], text=True).strip()
        match = re.fullmatch(r"(1|2)\.\d+\.\d+(?:[-+].*)?", version)
        if not match:
            parser.error(f"Unrecognized OpenCode version: {version!r}")
        major = int(match[1])
    state = home / ".local/state/dotfiles-agents"
    state.mkdir(parents=True, exist_ok=True, mode=0o700)
    with (state / "sync.lock").open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        plan = build_plan(home, config_home, major, args.exclude)
        for path, _, kind, _ in plan.changes:
            print(f"{kind}: {path}")
        if args.apply:
            plan.apply(home)
        print(f"{len(plan.changes)} change(s)" + (" applied" if args.apply else " pending"))
        return int(args.check and bool(plan.changes))


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (ValueError, OSError, RuntimeError) as error:
        sys.exit(f"Agent sync failed: {error}")
