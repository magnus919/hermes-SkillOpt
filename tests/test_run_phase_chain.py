from __future__ import annotations

import json
import os
from pathlib import Path
import stat
import subprocess
import tempfile
import unittest


REPO_ROOT = Path(__file__).resolve().parents[1]
RUN_PHASE = REPO_ROOT / "scripts" / "run-phase.sh"


class RunPhaseChainTests(unittest.TestCase):
    def test_stub_hermes_phase_chain_reaches_merge(self) -> None:
        with tempfile.TemporaryDirectory(prefix="skillopt-phase-chain-") as temp_dir:
            root = Path(temp_dir)
            skillopt_dir = root / "SkillOpt"
            state_dir = skillopt_dir / "smoke"
            state_dir.mkdir(parents=True)

            target = root / "target-skill" / "SKILL.md"
            target.parent.mkdir()
            target.write_text("# Smoke skill\n", encoding="utf-8")

            metadata = {
                "target": str(target),
                "skill_name": "smoke",
                "skill_slug": "smoke",
                "board_slug": "skillopt-smoke",
                "training_count": 1,
                "validation_count": 1,
                "edit_budget": 1,
                "initial_edit_budget": 1,
                "budget_floor": 1,
                "max_epochs": 2,
                "epoch": 1,
                "created_at": "2026-07-22T00:00:00Z",
                "baseline_snapshot": "epoch-0",
                "status": "active",
                "pass_rate_history": [],
                "metric_weights": {
                    "pass_rate": 1.0,
                    "quality_score": 0.0,
                    "speed_score": 0.0,
                    "token_efficiency": 0.0,
                },
            }
            (state_dir / "board-metadata.json").write_text(
                json.dumps(metadata), encoding="utf-8"
            )
            suite = {
                "training": [
                    {"id": "train-1", "instruction": "Run the smoke task"}
                ],
                "validation": [
                    {"id": "val-1", "instruction": "Validate the smoke task"}
                ],
                "created_at": "2026-07-22T00:00:00Z",
                "skill_target": str(target),
            }
            (state_dir / "test-suite.json").write_text(
                json.dumps(suite), encoding="utf-8"
            )

            stub = root / "hermes-stub"
            stub.write_text(
                """#!/usr/bin/env python3
import json
import sys
prompt = sys.argv[2]
if "You are analyzing the results" in prompt:
    result = {"epoch": 1, "rollout_count": 1, "success_count": 1, "failure_count": 0, "failure_patterns": [], "summary": "smoke reflection"}
elif "You are proposing edits" in prompt:
    result = {"epoch": 1, "budget": 1, "proposals": [{"id": "edit-1", "type": "add", "location": "end", "old_text": None, "new_text": "## Smoke addition\\nValidated by the phase-chain smoke test.\\n", "rationale": "exercise merge"}]}
elif "successfully handle this task?" in prompt:
    result = {"pass": True, "quality_score": 1.0, "reason": "smoke pass", "total_tokens": 10}
else:
    result = {"task_output": "smoke rollout"}
print(json.dumps(result))
""",
                encoding="utf-8",
            )
            stub.chmod(stub.stat().st_mode | stat.S_IXUSR)

            env = os.environ.copy()
            env.pop("PYTHONPATH", None)
            env.update({"SKILLOPT_DIR": str(skillopt_dir), "HERMES": str(stub)})

            for phase in ("rollout", "reflect", "propose", "validate", "merge"):
                result = subprocess.run(
                    [
                        "bash",
                        str(RUN_PHASE),
                        "--board",
                        "skillopt-smoke",
                        "--phase",
                        phase,
                        "--epoch",
                        "1",
                        "--exec",
                    ],
                    cwd=REPO_ROOT,
                    env=env,
                    capture_output=True,
                    text=True,
                )
                self.assertEqual(
                    result.returncode,
                    0,
                    f"{phase} failed:\n{result.stdout}\n{result.stderr}",
                )

            self.assertIn(
                "Validated by the phase-chain smoke test.",
                target.read_text(encoding="utf-8"),
            )
            final_metadata = json.loads(
                (state_dir / "board-metadata.json").read_text(encoding="utf-8")
            )
            self.assertEqual(final_metadata["epoch"], 2)
            self.assertTrue(
                (state_dir / "03-dossiers" / "epoch-1-reflection.json").is_file()
            )
            self.assertTrue(
                (state_dir / "03-dossiers" / "epoch-1-proposals.json").is_file()
            )
