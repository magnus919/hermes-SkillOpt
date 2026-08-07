from __future__ import annotations

import json
from pathlib import Path
import re
import unittest


REPO_ROOT = Path(__file__).resolve().parents[1]


class RepositoryContractTests(unittest.TestCase):
    def test_templates_are_valid_json_with_required_schema_shape(self) -> None:
        templates = {
            path.name: json.loads(path.read_text(encoding="utf-8"))
            for path in sorted((REPO_ROOT / "templates").glob("*.json"))
        }
        self.assertIn("board.json", templates)
        self.assertIn("test-suite.json", templates)
        board = templates["board.json"]
        suite = templates["test-suite.json"]

        self.assertEqual(board["type"], "object")
        self.assertIn("target", board["required"])
        self.assertIn("status", board["required"])
        self.assertEqual(suite["type"], "object")
        self.assertEqual(set(suite["required"]), {"training", "validation", "created_at", "skill_target"})
        self.assertEqual(suite["properties"]["training"]["minItems"], 1)
        self.assertEqual(suite["properties"]["validation"]["minItems"], 1)

    def test_shell_entry_points_have_strict_mode_and_executable_bit(self) -> None:
        for script in sorted((REPO_ROOT / "scripts").glob("*.sh")):
            content = script.read_text(encoding="utf-8")
            self.assertTrue(content.startswith("#!/usr/bin/env bash"), script)
            self.assertIn("set -euo pipefail", content, script)
            self.assertTrue(script.stat().st_mode & 0o111, script)

    def test_skill_document_has_lifecycle_and_resolvable_catalogs(self) -> None:
        skill = (REPO_ROOT / "SKILL.md").read_text(encoding="utf-8")
        self.assertTrue(skill.startswith("---\n"))
        frontmatter, body = skill.split("\n---\n", 1)
        self.assertIn("name: skillopt", frontmatter)
        self.assertIn("source_repo: \"https://github.com/magnus919/hermes-SkillOpt\"", frontmatter)
        for phase in ("Rollout", "Reflect", "Propose", "Validate", "Merge", "Slow/Meta"):
            self.assertIn(phase, body)

        scripts_section = body.split("## Scripts — Power Users Only", 1)[1].split("## References", 1)[0]
        references_section = body.split("## References", 1)[1].split("## Design Principles", 1)[0]
        script_paths = set(re.findall(r"`(scripts/[A-Za-z0-9_.-]+\.(?:sh|py))`", scripts_section))
        reference_paths = set(re.findall(r"`(references/[A-Za-z0-9_.-]+\.md)`", references_section))
        self.assertTrue(script_paths)
        self.assertTrue(reference_paths)
        for relative_path in sorted(script_paths | reference_paths):
            self.assertTrue((REPO_ROOT / relative_path).is_file(), relative_path)

        agents = (REPO_ROOT / "AGENTS.md").read_text(encoding="utf-8")
        self.assertIn("bash -n scripts/*.sh", agents)
        self.assertIn("parse `templates/*.json`", agents)
        self.assertIn("stub-Hermes smoke test", agents)


if __name__ == "__main__":
    unittest.main()
