"""Shared deterministic fixtures for SkillOpt repository tests."""

from __future__ import annotations

import json
import os
from pathlib import Path
import stat
import subprocess
from typing import Iterable, Mapping, Optional, Sequence


REPO_ROOT = Path(__file__).resolve().parents[1]


def make_target(root: Path, skill_name: str = "example-skill", content: str = "# Example skill\n") -> Path:
    target = root / skill_name / "SKILL.md"
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(content, encoding="utf-8")
    return target


def write_executable(path: Path, content: str) -> Path:
    path.write_text(content, encoding="utf-8")
    path.chmod(path.stat().st_mode | stat.S_IXUSR)
    return path


def write_hermes_stub(path: Path) -> Path:
    """Write a CLI stub that records calls and implements required zero exits."""
    script = '''#!/usr/bin/env python3
import json
import os
from pathlib import Path
import sys

args = sys.argv[1:]
log_path = os.environ.get("HERMES_LOG")
if log_path:
    with Path(log_path).open("a", encoding="utf-8") as handle:
        json.dump(args, handle)
        handle.write("\\n")

if args[:3] == ["kanban", "boards", "list"]:
    print(os.environ.get("HERMES_BOARD_LIST", ""))
elif args[:4] == ["kanban", "boards", "create", ""]:
    pass
# All other documented calls are accepted and recorded. The tests assert the
# important command shapes from the log rather than relying on side effects.
sys.exit(0)
'''
    write_executable(path, script)
    return path


def test_env(root: Path, hermes: Path, skillopt_dir: Optional[Path] = None) -> dict[str, str]:
    env = os.environ.copy()
    env.pop("PYTHONPATH", None)
    env.update(
        {
            "HERMES": str(hermes),
            "HERMES_LOG": str(root / "hermes-calls.jsonl"),
            "SKILLOPT_DIR": str(skillopt_dir or root / "SkillOpt"),
        }
    )
    return env


def run_script(
    script: Path,
    args: Sequence[str],
    env: Mapping[str, str],
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["bash", str(script), *args],
        cwd=REPO_ROOT,
        env=dict(env),
        capture_output=True,
        text=True,
        check=False,
    )


def read_json_lines(path: Path) -> list[list[str]]:
    if not path.exists():
        return []
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines()]


def command_matches(calls: Iterable[list[str]], prefix: Sequence[str]) -> list[list[str]]:
    prefix = list(prefix)
    return [call for call in calls if call[: len(prefix)] == prefix]
