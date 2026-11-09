"""Shared deterministic fixtures for SkillOpt repository tests."""

from __future__ import annotations

import json
import os
from pathlib import Path
import shutil
import stat
import subprocess
import sys
from typing import Iterable, Mapping, Optional, Sequence


REPO_ROOT = Path(__file__).resolve().parents[1]


def sh_path(value) -> str:
    """Path form bash can execute.

    On Windows, str(path) yields a drive path with backslashes; MSYS bash treats
    them as escapes and reports "No such file or directory". Forward slashes work
    in both bash and native Windows programs, so normalise on nt.
    """
    text = str(value)
    return text.replace(chr(92), "/") if os.name == "nt" else text


def hermes_cmd(stub: Path) -> str:
    """HERMES value that the runner can actually execute on this OS.

    run-phase.sh shlex-splits HERMES and execs it. A shebang script with no
    extension is not executable on Windows (CreateProcess rejects it), so wrap
    the stub in the interpreter there.
    """
    if os.name != "nt":
        return str(stub)
    return f'"{sys.executable}" "{stub}"'


def bash_exe() -> str:
    """A bash that can execute a Windows path.

    On Windows a bare ``bash`` resolves through CreateProcess to
    ``C:\Windows\System32\bash.exe`` (WSL), which has its own filesystem and
    cannot open ``C:/...`` script paths - every script call exits 127. Prefer a
    Git-for-Windows/MSYS bash, which handles drive paths natively.
    """
    if os.name != "nt":
        return "bash"
    found = shutil.which("bash")
    if found and "system32" not in found.lower():
        return found
    for candidate in (r"C:/Program Files/Git/bin/bash.exe",
                      r"C:/Program Files (x86)/Git/bin/bash.exe"):
        if os.path.exists(candidate):
            return candidate
    return found or "bash"


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
            "HERMES": sh_path(hermes),
            "HERMES_LOG": sh_path(root / "hermes-calls.jsonl"),
            "SKILLOPT_DIR": sh_path(skillopt_dir or root / "SkillOpt"),
        }
    )
    return env


def run_script(
    script: Path,
    args: Sequence[str],
    env: Mapping[str, str],
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [bash_exe(), sh_path(script), *(sh_path(a) for a in args)],
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
