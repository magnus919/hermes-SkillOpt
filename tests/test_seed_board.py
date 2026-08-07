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


SEED_BOARD = REPO_ROOT / "scripts" / "seed-board.sh"


class SeedBoardTests(unittest.TestCase):
    def test_special_characters_survive_seed_and_task_creation(self) -> None:
        with tempfile.TemporaryDirectory(prefix="skillopt-seed-") as temp_dir:
            root = Path(temp_dir)
            target = make_target(root, content="# Baseline\n")
            hermes = write_hermes_stub(root / "hermes-stub")
            train_file = root / "training.json"
            val_file = root / "validation.json"
            instruction = 'Use "quotes", `backticks`, $(not shell), and a literal triple quote: """.'
            train_file.write_text(
                json.dumps(
                    [
                        {"id": "train-special", "instruction": instruction},
                        {"id": "train-two", "instruction": "second task"},
                    ]
                ),
                encoding="utf-8",
            )
            val_file.write_text(
                json.dumps([{"id": "val-one", "instruction": "held-out"}]),
                encoding="utf-8",
            )

            result = run_script(
                SEED_BOARD,
                [
                    "--target",
                    str(target),
                    "--training",
                    "99",
                    "--validation",
                    "99",
                    "--train-tasks-file",
                    str(train_file),
                    "--val-tasks-file",
                    str(val_file),
                    "--budget",
                    "3",
                ],
                test_env(root, hermes),
            )

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            state_dir = root / "SkillOpt" / "example-skill"
            suite = json.loads((state_dir / "test-suite.json").read_text(encoding="utf-8"))
            self.assertEqual(suite["training"][0]["instruction"], instruction)
            self.assertEqual(len(suite["training"]), 2)
            self.assertEqual(len(suite["validation"]), 1)

            metadata = json.loads((state_dir / "board-metadata.json").read_text(encoding="utf-8"))
            self.assertEqual(metadata["skill_slug"], "example-skill")
            self.assertEqual(metadata["training_count"], 2)
            self.assertEqual(metadata["validation_count"], 1)
            self.assertEqual(metadata["edit_budget"], 3)

            snapshots = list((state_dir / "snapshots").glob("baseline-*.md"))
            self.assertEqual(len(snapshots), 1)
            self.assertEqual(snapshots[0].read_text(encoding="utf-8"), "# Baseline\n")

            calls = read_json_lines(root / "hermes-calls.jsonl")
            board_creates = command_matches(calls, ["kanban", "boards", "create"])
            task_creates = command_matches(calls, ["kanban", "--board", "skillopt-example-skill", "create"])
            self.assertEqual(len(board_creates), 1)
            self.assertEqual(len(task_creates), 3)  # two rollout tasks + baseline task
            self.assertTrue(any(instruction in " ".join(call) for call in task_creates))

    def test_missing_instruction_is_rejected_before_state_creation(self) -> None:
        with tempfile.TemporaryDirectory(prefix="skillopt-seed-invalid-") as temp_dir:
            root = Path(temp_dir)
            target = make_target(root)
            hermes = write_hermes_stub(root / "hermes-stub")
            bad_tasks = root / "bad.json"
            bad_tasks.write_text(json.dumps([{"id": "missing-instruction"}]), encoding="utf-8")

            result = run_script(
                SEED_BOARD,
                [
                    "--target",
                    str(target),
                    "--training",
                    "1",
                    "--validation",
                    "1",
                    "--train-tasks-file",
                    str(bad_tasks),
                ],
                test_env(root, hermes),
            )

            self.assertNotEqual(result.returncode, 0)
            self.assertIn('missing "instruction" field', result.stderr)
            self.assertFalse((root / "SkillOpt").exists())

    def test_non_positive_or_non_numeric_counts_are_rejected(self) -> None:
        cases = (("0", "1"), ("1", "0"), ("not-a-number", "1"))
        with tempfile.TemporaryDirectory(prefix="skillopt-seed-counts-") as temp_dir:
            root = Path(temp_dir)
            target = make_target(root)
            hermes = write_hermes_stub(root / "hermes-stub")

            for training, validation in cases:
                with self.subTest(training=training, validation=validation):
                    result = run_script(
                        SEED_BOARD,
                        [
                            "--target",
                            str(target),
                            "--training",
                            training,
                            "--validation",
                            validation,
                        ],
                        test_env(root, hermes),
                    )
                    self.assertNotEqual(result.returncode, 0)
                    self.assertIn("must be a positive integer", result.stderr)
                    self.assertFalse((root / "SkillOpt").exists())

            empty_tasks = root / "empty.json"
            empty_tasks.write_text("[]", encoding="utf-8")
            result = run_script(
                SEED_BOARD,
                [
                    "--target",
                    str(target),
                    "--training",
                    "1",
                    "--validation",
                    "1",
                    "--train-tasks-file",
                    str(empty_tasks),
                ],
                test_env(root, hermes),
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("must be a positive integer", result.stderr)
            self.assertFalse((root / "SkillOpt").exists())

    def test_existing_board_is_rejected_without_creating_state(self) -> None:
        with tempfile.TemporaryDirectory(prefix="skillopt-seed-duplicate-") as temp_dir:
            root = Path(temp_dir)
            target = make_target(root)
            hermes = write_hermes_stub(root / "hermes-stub")
            env = test_env(root, hermes)
            env["HERMES_BOARD_LIST"] = "skillopt-example-skill"

            result = run_script(
                SEED_BOARD,
                ["--target", str(target), "--training", "1", "--validation", "1"],
                env,
            )

            self.assertNotEqual(result.returncode, 0)
            self.assertIn("already exists", result.stdout)
            self.assertFalse((root / "SkillOpt").exists())


if __name__ == "__main__":
    unittest.main()
