from __future__ import annotations

import json
from pathlib import Path
import tempfile
import unittest

from tests.support import (
    REPO_ROOT,
    command_matches,
    make_target,
    read_json_lines,
    run_script,
    test_env,
    write_hermes_stub,
)


ARCHIVE_RUN = REPO_ROOT / "scripts" / "archive-run.sh"


class ArchiveRunTests(unittest.TestCase):
    def test_archive_regenerates_pyramid_and_preserves_state_before_cleanup(self) -> None:
        with tempfile.TemporaryDirectory(prefix="skillopt-archive-") as temp_dir:
            root = Path(temp_dir)
            target = make_target(root)
            state_dir = root / "SkillOpt" / "example-skill"
            dossiers = state_dir / "03-dossiers"
            dossiers.mkdir(parents=True)
            metadata = {
                "target": str(target),
                "skill_name": "example-skill",
                "skill_slug": "example-skill",
                "board_slug": "skillopt-example-skill",
                "epoch": 1,
                "status": "active",
                "pass_rate_history": [
                    {"epoch": 1, "pass_rate": 0.75, "accepted": 0, "rejected": 1}
                ],
            }
            (state_dir / "board-metadata.json").write_text(
                json.dumps(metadata), encoding="utf-8"
            )
            for name in (
                "epoch-1-rollout-train-one.json",
                "epoch-1-reflection.json",
                "epoch-1-proposals.json",
                "epoch-1-validation-baseline.json",
                "epoch-1.json",
            ):
                (dossiers / name).write_text("{}\n", encoding="utf-8")

            hermes = write_hermes_stub(root / "hermes-stub")
            env = test_env(root, hermes)
            env["HERMES_BOARD_LIST"] = "skillopt-example-skill"

            kept = run_script(
                ARCHIVE_RUN,
                ["--board", "SkillOpt-Example_Skill", "--keep-state"],
                env,
            )
            self.assertEqual(kept.returncode, 0, kept.stdout + kept.stderr)
            self.assertIn("Board preserved", kept.stdout)
            self.assertIn("final_pass_rate: 0.75", (state_dir / "01-summary" / "findings.md").read_text(encoding="utf-8"))
            self.assertIn("epoch-1-overview.md", (state_dir / "00-index.md").read_text(encoding="utf-8"))
            overview = (state_dir / "02-analysis" / "epoch-1-overview.md").read_text(encoding="utf-8")
            self.assertIn("**Rollout:** 1 dossier(s)", overview)
            self.assertIn("**Reflection:** 1 dossier(s)", overview)
            self.assertIn("03-dossiers/epoch-1-reflection.json", overview)
            self.assertIn("**Proposals:** 1 dossier(s)", overview)
            self.assertIn("03-dossiers/epoch-1-proposals.json", overview)
            self.assertIn("03-dossiers/epoch-1-validation-baseline.json", overview)
            self.assertNotIn("epoch-1.json", overview)
            self.assertFalse(command_matches(read_json_lines(root / "hermes-calls.jsonl"), ["kanban", "boards", "rm"]))

            removed = run_script(ARCHIVE_RUN, ["--board", "skillopt-example-skill"], env)
            self.assertEqual(removed.returncode, 0, removed.stdout + removed.stderr)
            self.assertTrue(command_matches(read_json_lines(root / "hermes-calls.jsonl"), ["kanban", "boards", "rm"]))
            self.assertTrue(state_dir.exists(), "archive must preserve the state directory")


if __name__ == "__main__":
    unittest.main()
