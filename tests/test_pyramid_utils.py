from __future__ import annotations

import json
from pathlib import Path
import tempfile
import unittest

from scripts import pyramid_utils


class PyramidUtilsTests(unittest.TestCase):
    def test_update_root_pyramid_indexes_epochs_and_phase_dossiers(self) -> None:
        with tempfile.TemporaryDirectory(prefix="skillopt-pyramid-") as temp_dir:
            state_dir = Path(temp_dir)
            dossiers = state_dir / "03-dossiers"
            dossiers.mkdir()
            metadata = {
                "target": "/tmp/example-skill/SKILL.md",
                "pass_rate_history": [
                    {"epoch": 1, "pass_rate": 0.5, "accepted": 0, "rejected": 1},
                    {"epoch": 2, "pass_rate": 1.0, "accepted": 1, "rejected": 0},
                ],
            }
            (state_dir / "board-metadata.json").write_text(
                json.dumps(metadata), encoding="utf-8"
            )
            for name in (
                "epoch-2-validation-final.json",
                "epoch-1-rollout-first.json",
                "epoch-2-reflection.json",
                "epoch-2-proposals.json",
                "epoch-2.json",
                "not-an-epoch.json",
            ):
                (dossiers / name).write_text("{}\n", encoding="utf-8")

            pyramid_utils.update_root_pyramid(str(state_dir), "2")

            index = (state_dir / "00-index.md").read_text(encoding="utf-8")
            self.assertLess(index.index("epoch-1-overview.md"), index.index("epoch-2-overview.md"))
            summary = (state_dir / "01-summary" / "findings.md").read_text(encoding="utf-8")
            self.assertIn("final_epoch: 2", summary)
            self.assertIn("final_pass_rate: 1.0", summary)
            trajectory = (state_dir / "02-analysis" / "epoch-trajectory.md").read_text(encoding="utf-8")
            self.assertIn("| 1 | 0.5 |", trajectory)
            self.assertIn("| 2 | 1.0 |", trajectory)
            overview = (state_dir / "02-analysis" / "epoch-2-overview.md").read_text(encoding="utf-8")
            self.assertIn("**Reflection:** 1 dossier(s)", overview)
            self.assertIn("03-dossiers/epoch-2-reflection.json", overview)
            self.assertIn("**Proposals:** 1 dossier(s)", overview)
            self.assertIn("03-dossiers/epoch-2-proposals.json", overview)
            self.assertIn("03-dossiers/epoch-2-validation-final.json", overview)
            self.assertNotIn("epoch-2.json", overview)
            self.assertNotIn("not-an-epoch.json", overview)


if __name__ == "__main__":
    unittest.main()
