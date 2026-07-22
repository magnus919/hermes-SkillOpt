from __future__ import annotations

import json
import os
from pathlib import Path
import stat
import subprocess
import tempfile
import textwrap
import unittest


REPO_ROOT = Path(__file__).resolve().parents[1]
SCRIPTS_DIR = REPO_ROOT / "scripts"
RUN_PHASE = SCRIPTS_DIR / "run-phase.sh"


class RunPhaseTests(unittest.TestCase):
    def test_shell_scripts_pass_bash_syntax_check(self) -> None:
        failures: list[str] = []

        for script in sorted(SCRIPTS_DIR.glob("*.sh")):
            result = subprocess.run(
                ["bash", "-n", str(script)],
                capture_output=True,
                text=True,
            )
            if result.returncode != 0:
                failures.append(f"{script.name}: {result.stderr.strip()}")

        self.assertFalse(failures, "\n".join(failures))

    def test_reflect_aggregates_rollouts_into_hermes_prompt(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            tmp_path = Path(temp_dir)
            skillopt_dir = tmp_path / "SkillOpt"
            state_dir = skillopt_dir / "demo"
            dossiers_dir = state_dir / "03-dossiers"
            dossiers_dir.mkdir(parents=True)

            target = tmp_path / "target-skill" / "SKILL.md"
            target.parent.mkdir()
            target.write_text("# Demo skill\n", encoding="utf-8")

            metadata = {
                "target": str(target),
                "edit_budget": 4,
                "epoch": 1,
                "pass_rate_history": [],
            }
            (state_dir / "board-metadata.json").write_text(
                json.dumps(metadata), encoding="utf-8"
            )

            rollout_records = [
                {"task_id": "train-alpha", "result": {"pass": True}},
                {"task_id": "train-beta", "result": {"pass": False}},
            ]
            for record in rollout_records:
                path = dossiers_dir / f"epoch-1-rollout-{record['task_id']}.json"
                path.write_text(json.dumps(record), encoding="utf-8")

            captured_prompt = tmp_path / "captured-prompt.txt"
            hermes_stub = tmp_path / "hermes-stub"
            hermes_stub.write_text(
                textwrap.dedent(
                    """\
                    #!/usr/bin/env python3
                    import json
                    import os
                    from pathlib import Path
                    import sys

                    assert sys.argv[1] == "-z"
                    Path(os.environ["CAPTURED_PROMPT"]).write_text(
                        sys.argv[2], encoding="utf-8"
                    )
                    print(json.dumps({
                        "epoch": 1,
                        "rollout_count": 2,
                        "success_count": 1,
                        "failure_count": 1,
                        "failure_patterns": [],
                        "summary": "fixture reflection",
                    }))
                    """
                ),
                encoding="utf-8",
            )
            hermes_stub.chmod(hermes_stub.stat().st_mode | stat.S_IXUSR)

            shadow_marker = tmp_path / "shadow-module-loaded"
            (tmp_path / "pyramid_utils.py").write_text(
                "from pathlib import Path\n"
                f"Path({str(shadow_marker)!r}).write_text('loaded')\n"
                "def update_root_pyramid(*args, **kwargs):\n"
                "    return None\n",
                encoding="utf-8",
            )
            runner_target = tmp_path / "runner-target"
            runner_target.symlink_to(RUN_PHASE)
            runner_link = tmp_path / "run-phase.sh"
            runner_link.symlink_to(runner_target.name)

            env = os.environ.copy()
            env.pop("PYTHONPATH", None)
            env.update(
                {
                    "SKILLOPT_DIR": str(skillopt_dir),
                    "HERMES": str(hermes_stub),
                    "CAPTURED_PROMPT": str(captured_prompt),
                }
            )

            result = subprocess.run(
                [
                    "bash",
                    str(runner_link),
                    "--board",
                    "skillopt-demo",
                    "--phase",
                    "reflect",
                    "--epoch",
                    "1",
                    "--exec",
                ],
                cwd=tmp_path,
                env=env,
                capture_output=True,
                text=True,
            )

            self.assertEqual(
                result.returncode, 0, result.stderr or result.stdout
            )
            self.assertFalse(
                shadow_marker.exists(),
                "run-phase.sh imported pyramid_utils from a symlink directory",
            )
            prompt = captured_prompt.read_text(encoding="utf-8")
            self.assertIn('"task_id": "train-alpha"', prompt)
            self.assertIn('"task_id": "train-beta"', prompt)
            self.assertIn("2 training tasks were executed", prompt)

            reflection = json.loads(
                (dossiers_dir / "epoch-1-reflection.json").read_text(
                    encoding="utf-8"
                )
            )
            self.assertEqual(reflection["rollout_count"], 2)
            self.assertEqual(reflection["summary"], "fixture reflection")
