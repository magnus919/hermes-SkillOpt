"""Tests for run_post_merge_task token_estimate consistency (issue #19).

The bug (issue #19): the success path of run_post_merge_task in
scripts/run-phase.sh computes token_estimate as

    (len(prompt) + len(merged_skill) + len(result.stdout or "") + 3) // 4

while the failure path (non-zero returncode) includes len(result.stderr or "")
for consistency. The success path should also include stderr so that
token_estimate is computed uniformly across paths (matching the
validate-phase normalize_verdict() pattern).

These tests extract the function source from scripts/run-phase.sh and
execute it in a controlled namespace with mocked subprocess / workspace
factories, so the tests verify the actual production code rather than a
copy.
"""
from __future__ import annotations

import json
import os
import re
import textwrap
import unittest
from unittest.mock import MagicMock

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir))
SCRIPT_PATH = os.path.join(REPO_ROOT, "scripts", "run-phase.sh")


def _extract_function_source() -> str:
    """Return the source of run_post_merge_task as it appears in run-phase.sh."""
    with open(SCRIPT_PATH, "r", encoding="utf-8") as f:
        content = f.read()

    # The function lives inside a python heredoc delimited by 'PYEOF'.
    heredoc_re = re.compile(
        r"python3(?:\s+-)?\s*<<\s*'PYEOF'\n(.*?)\nPYEOF",
        re.DOTALL,
    )
    for match in heredoc_re.finditer(content):
        block = match.group(1)
        if "def run_post_merge_task" not in block:
            continue
        # Pull the function out by line numbers: from `def run_post_merge_task`
        # to the next top-level `def ` / `class ` or end of block.
        lines = block.split("\n")
        start = next(
            i for i, line in enumerate(lines)
            if line.startswith("def run_post_merge_task")
        )
        end = len(lines)
        for j in range(start + 1, len(lines)):
            stripped = lines[j]
            if stripped.startswith("def ") or stripped.startswith("class "):
                end = j
                break
        return "\n".join(lines[start:end])

    raise RuntimeError(
        "Could not locate run_post_merge_task inside any python heredoc in "
        f"{SCRIPT_PATH}"
    )


# Compute the expected token_estimate formula on the success path *after* the
# fix. Mirrors the failure-path formula but with stderr included.
def _expected_success_token_estimate(
    prompt: str, merged_skill: str, stdout: str, stderr: str
) -> int:
    return int(
        (
            len(prompt)
            + len(merged_skill)
            + len(stdout or "")
            + len(stderr or "")
            + 3
        )
        // 4
    )


# And the pre-fix formula (for the negative assertion in the
# test_success_path_excludes_stderr_token_estimate_under_bug case — kept
# here so the expected values are obviously derived).
def _buggy_success_token_estimate(
    prompt: str, merged_skill: str, stdout: str, stderr: str
) -> int:
    return int(
        (len(prompt) + len(merged_skill) + len(stdout or "") + 3) // 4
    )


class _FunctionSandbox:
    """Builds a controlled namespace and exec's run_post_merge_task into it."""

    def __init__(self) -> None:
        self.source = _extract_function_source()
        self.workspace = MagicMock(name="workspace")
        self.workspace.name = "/tmp/skillopt-postmerge-workspace-fake"
        self.skill_dir = "/tmp/skillopt-postmerge-workspace-fake/skillopt"
        self.skill_path = self.skill_dir + "/SKILL.md"

        # Wire up the namespace: real stdlib modules we want to keep real,
        # everything else from the function's closure mocked.
        self.ns: dict = {
            "__name__": "test_run_post_merge_task",
            "subprocess": MagicMock(name="subprocess"),
            "time": MagicMock(name="time"),
            "tempfile": MagicMock(name="tempfile"),
            "shutil": MagicMock(name="shutil"),
            "os": MagicMock(name="os"),
            "shlex": MagicMock(name="shlex"),
            "json": json,  # real json
            "create_candidate_workspace": MagicMock(
                name="create_candidate_workspace",
                return_value=(self.workspace, self.skill_dir, self.skill_path),
            ),
            # Closure globals referenced inside the function
            "hermes": "hermes",
            "target": "/tmp/fake-skill.md",
        }
        # time.monotonic() needs to be a callable that returns increasing
        # values so the duration computation produces a positive number.
        # Each call to run_post_merge_task invokes time.monotonic() twice
        # (once for `started`, once for `duration`), so use itertools.count
        # to supply an unbounded, monotonically increasing stream.
        import itertools

        self._mono_counter = itertools.count(start=100.0, step=0.25)
        self.ns["time"].monotonic.side_effect = lambda: next(self._mono_counter)

        exec(self.source, self.ns)
        self.func = self.ns["run_post_merge_task"]

    def make_subprocess_result(
        self,
        returncode: int = 0,
        stdout: str = "",
        stderr: str = "",
    ) -> MagicMock:
        result = MagicMock(name="CompletedProcess")
        result.returncode = returncode
        result.stdout = stdout
        result.stderr = stderr
        return result

    def call(
        self,
        merged_skill: str = "merged skill body",
        task: dict | None = None,
        stdout: str = "",
        stderr: str = "",
        returncode: int = 0,
    ) -> dict:
        if task is None:
            task = {"instruction": "do a thing"}
        result = self.make_subprocess_result(
            returncode=returncode, stdout=stdout, stderr=stderr
        )
        self.ns["subprocess"].run.return_value = result
        return self.func(merged_skill, task)

    @property
    def prompt(self) -> str:
        """The prompt template the function builds (via the mocked workspace)."""
        # Re-derive the same f-string the function uses so test assertions can
        # compute expected values without re-running the function.
        task_inst = "do a thing"
        return textwrap.dedent(
            f"""\
            Evaluate this merged skill workspace against the following task.

            === SKILL WORKSPACE ===
            {self.skill_dir}

            === SKILL DOCUMENT PATH ===
            {self.skill_path}

            Read the skill document first. If the task depends on linked or sibling support files, inspect files inside this workspace only, including README.md, AGENTS.md, references/, scripts/, templates/, and assets/ when present. Do not inspect or modify the original installed skill outside this workspace. Do not modify files.

            === TASK ===
            {task_inst}

            Does this skill successfully handle this task? Respond with ONLY a JSON object:
            {{"pass": true/false, "quality_score": 0.0-1.0, "reason": "brief explanation"}}"""
        )


class RunPostMergeTaskTokenEstimateTests(unittest.TestCase):
    """Regression tests for issue #19 — token_estimate must include stderr."""

    def setUp(self) -> None:
        self.sandbox = _FunctionSandbox()

    def test_success_path_includes_stderr_in_token_estimate(self) -> None:
        """After fix: success-path token_estimate = prompt + skill + stdout + stderr + 3 // 4."""
        merged_skill = "x" * 4000
        stdout = '{"pass": true, "quality_score": 0.9, "reason": "ok"}\n'
        stderr = "warning: model cache miss\nwarning: slow token bucket\n"

        result = self.sandbox.call(
            merged_skill=merged_skill,
            stdout=stdout,
            stderr=stderr,
        )

        self.assertTrue(result["pass"], result)
        self.assertEqual(
            result["token_estimate"],
            _expected_success_token_estimate(
                self.sandbox.prompt, merged_skill, stdout, stderr
            ),
            f"success-path token_estimate must include stderr length, got "
            f"{result['token_estimate']} (expected "
            f"{_expected_success_token_estimate(self.sandbox.prompt, merged_skill, stdout, stderr)})",
        )

    def test_success_path_matches_failure_path_when_stderr_is_nonzero(self) -> None:
        """The fix should make the success path consistent with the failure path.

        Both paths should now use the same (prompt + skill + stdout + stderr + 3) // 4
        formula. Verify by computing both and asserting equality.
        """
        merged_skill = "skill text"
        stdout = '{"pass": true, "quality_score": 0.8, "reason": "good"}\n'
        stderr = "warning: something\n"

        # Success path
        success = self.sandbox.call(
            merged_skill=merged_skill,
            stdout=stdout,
            stderr=stderr,
        )
        # Failure path (returncode != 0)
        failure = self.sandbox.call(
            merged_skill=merged_skill,
            stdout=stdout,
            stderr=stderr,
            returncode=1,
        )

        # Under the fix, both formulas are identical: the success path now
        # includes len(result.stderr or "") exactly like the failure path.
        success_formula = _expected_success_token_estimate(
            self.sandbox.prompt, merged_skill, stdout, stderr
        )
        self.assertEqual(success["token_estimate"], success_formula)
        self.assertEqual(failure["token_estimate"], success_formula)
        self.assertEqual(
            success["token_estimate"],
            failure["token_estimate"],
            "success and failure paths must produce identical token_estimate",
        )

    def test_empty_stderr_on_success_path_still_consistent(self) -> None:
        """When stderr is empty, including or excluding it is equivalent —
        but the formula must still be well-defined and match the failure path."""
        merged_skill = "abc"
        stdout = '{"pass": true, "quality_score": 1.0, "reason": "ok"}'
        stderr = ""

        result = self.sandbox.call(
            merged_skill=merged_skill,
            stdout=stdout,
            stderr=stderr,
        )
        self.assertTrue(result["pass"])
        expected = _expected_success_token_estimate(
            self.sandbox.prompt, merged_skill, stdout, stderr
        )
        self.assertEqual(result["token_estimate"], expected)

    def test_nonempty_stderr_increases_token_estimate_above_stderrfree_baseline(self) -> None:
        """Sanity check: a stderr message must strictly increase token_estimate
        relative to the same call with empty stderr, because the formula
        explicitly adds len(stderr)."""
        merged_skill = "skill text"
        stdout = '{"pass": true, "quality_score": 0.7, "reason": "ok"}'
        empty_stderr = ""
        full_stderr = "x" * 400  # 100 extra tokens

        without = self.sandbox.call(
            merged_skill=merged_skill,
            stdout=stdout,
            stderr=empty_stderr,
        )
        with_stderr = self.sandbox.call(
            merged_skill=merged_skill,
            stdout=stdout,
            stderr=full_stderr,
        )
        self.assertGreater(
            with_stderr["token_estimate"],
            without["token_estimate"],
            "non-empty stderr must increase token_estimate (proves stderr is "
            "factored into the success-path formula)",
        )

    def test_buggy_formula_excludes_stderr(self) -> None:
        """Pre-fix formula produces a lower estimate when stderr is non-empty.

        This is the negative test from issue #21 that proves the bug existed.
        The buggy formula (missing stderr) must always be <= the fixed formula
        (including stderr), and strictly less when stderr is non-empty.
        """
        prompt = "x" * 100
        skill_text = "x" * 100
        stdout = "x" * 50
        stderr = "x" * 50
        buggy = _buggy_success_token_estimate(prompt, skill_text, stdout, stderr)
        fixed = _expected_success_token_estimate(prompt, skill_text, stdout, stderr)
        self.assertLess(
            buggy,
            fixed,
            "buggy formula (no stderr) should produce a lower token_estimate "
            "than the fixed formula when stderr is non-empty",
        )


if __name__ == "__main__":
    unittest.main()
