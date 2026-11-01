from __future__ import annotations

import importlib.util
import json
from pathlib import Path
import sys
import unittest


REPO_ROOT = Path(__file__).resolve().parents[1]


def _load_module():
    """Import scripts/hermes_contract.py without requiring the dir on sys.path."""
    truthy_spec = importlib.util.spec_from_file_location(
        "hermes_contract", REPO_ROOT / "scripts" / "hermes_contract.py")
    assert truthy_spec is not None and truthy_spec.loader is not None
    module = importlib.util.module_from_spec(truthy_spec)
    sys.modules[truthy_spec.name] = module
    truthy_spec.loader.exec_module(module)
    return module


hc = _load_module()


SAMPLE_HELP = """\
usage: hermes kanban [-h] [--board <slug>]
                     {init,boards,create,list,show} ...

Durable SQLite-backed task board shared across Hermes profiles.

positional arguments:
  {init,boards,create,list,show}

options:
  -h, --help            show this help message and exit
  --board <slug>        Board slug to operate on
"""


class HelpParsingTests(unittest.TestCase):
    def test_parses_flags_and_brace_subcommand_groups(self):
        parsed = hc.parse_help(SAMPLE_HELP)
        self.assertIn("--board", parsed["flags"])
        self.assertIn("--help", parsed["flags"])
        self.assertEqual(
            parsed["subcommands"],
            ["boards", "create", "init", "list", "show"],
        )

    def test_parses_positional_argument_listing(self):
        parsed = hc.parse_help(
            "usage: hermes [-h] [--version] <command> ...\n"
            "\n"
            "positional arguments:\n"
            "    chat                Interactive chat with the agent\n"
            "    kanban              Multi-profile collaboration board\n"
            "\n"
            "options:\n"
            "  -h, --help            show this help message and exit\n"
        )
        self.assertIn("chat", parsed["subcommands"])
        self.assertIn("kanban", parsed["subcommands"])
        self.assertIn("--version", parsed["flags"])


class CitationTests(unittest.TestCase):
    def test_keeps_token_order_across_interleaved_flags(self):
        citation = hc.parse_citation("hermes kanban --board demo list")
        self.assertEqual(citation["tokens"], ["kanban", "--board", "demo", "list"])

    def test_keeps_subcommand_path_tokens(self):
        citation = hc.parse_citation("hermes skills list --source local")
        self.assertEqual(citation["tokens"], ["skills", "list", "--source", "local"])

    def test_does_not_capture_non_hermes_spans(self):
        self.assertIsNone(hc.parse_citation("python3 scripts/run-phase.sh"))
        self.assertIsNone(hc.parse_citation("hermes"))


class ResolutionTests(unittest.TestCase):
    MANIFEST = {
        "schema": 1,
        "hermes_version": "test",
        "global_flags": ["-z", "--oneshot", "--skills", "--help", "-h"],
        "commands": {
            "kanban": {
                "flags": ["--board"],
                "subcommands": {
                    "list": {"flags": [], "subcommands": {}},
                    "boards": {"flags": [], "subcommands": {}},
                },
            },
            "skills": {
                "flags": [],
                "subcommands": {"list": {"flags": ["--source"], "subcommands": {}}},
            },
        },
    }

    def test_accepts_valid_subcommand_and_flag(self):
        citation = hc.parse_citation("hermes skills list --source local")
        self.assertIsNone(hc.resolve(self.MANIFEST, citation))

    def test_rejects_retired_verb_with_actionable_reason(self):
        citation = hc.parse_citation("hermes oneshot 'do the thing'")
        reason = hc.resolve(self.MANIFEST, citation)
        self.assertIsNotNone(reason)
        self.assertIn("not a subcommand", reason)
        self.assertIn("kanban", reason)  # names what does exist

    def test_rejects_unknown_flag(self):
        citation = hc.parse_citation("hermes kanban list --nonsense")
        reason = hc.resolve(self.MANIFEST, citation)
        self.assertIsNotNone(reason)
        self.assertIn("--nonsense", reason)

    def test_accepts_interleaved_parent_flag(self):
        citation = hc.parse_citation("hermes kanban --board demo list")
        self.assertIsNone(hc.resolve(self.MANIFEST, citation))

    def test_accepts_global_flag_citation(self):
        citation = hc.parse_citation("hermes -z 'prompt'")
        self.assertIsNone(hc.resolve(self.MANIFEST, citation))


class CheckedInContractTests(unittest.TestCase):
    """The gate that stops CLI drift from reaching users."""

    @classmethod
    def setUpClass(cls):
        cls.manifest = hc.load_manifest(REPO_ROOT)
        cls.citations = hc.extract_citations(REPO_ROOT)

    def test_manifest_declares_its_provenance(self):
        self.assertEqual(self.manifest["schema"], hc.SCHEMA_VERSION)
        self.assertTrue(self.manifest["hermes_version"])
        self.assertTrue(self.manifest["commands"])

    def test_every_documented_command_exists_in_the_declared_contract(self):
        failures = []
        for citation in self.citations:
            reason = hc.resolve(self.manifest, citation)
            if reason:
                failures.append("%s -> %s" % (citation["raw"], reason))
        self.assertEqual(
            failures, [],
            "Documented commands missing from contracts/hermes-cli-contract.json:\n  "
            + "\n  ".join(failures)
            + "\nRefresh with: python3 scripts/hermes_contract.py --refresh",
        )

    def test_documentation_cites_enough_commands_to_be_worth_checking(self):
        # Guards against a refactor that makes citation extraction silently
        # return nothing and therefore always pass.
        self.assertGreaterEqual(len(self.citations), 6)


class LoadabilityTests(unittest.TestCase):
    """A skill that stock Hermes never indexes cannot optimize anything."""

    def _frontmatter(self):
        text = (REPO_ROOT / "SKILL.md").read_text(encoding="utf-8")
        return text.split("\n---\n", 1)[0]

    def test_required_toolsets_do_not_gate_on_default_off_toolset(self):
        frontmatter = self._frontmatter()
        marker = "requires_toolsets:"
        if marker not in frontmatter:
            return
        declared = frontmatter.split(marker, 1)[1].splitlines()[0].strip()
        # 'kanban' ships disabled by default in Hermes (_DEFAULT_OFF_TOOLSETS),
        # so requiring it hides the skill from the index on every stock install.
        self.assertNotIn(
            "kanban", declared,
            "requires_toolsets must not include 'kanban': it is off by default "
            "in Hermes, which hides this skill entirely. Declare terminal only "
            "and document the board as optional.",
        )

    def test_compatibility_names_the_current_noninteractive_flag(self):
        frontmatter = self._frontmatter()
        self.assertIn("-z", frontmatter)
        self.assertNotIn("hermes oneshot", frontmatter)


if __name__ == "__main__":
    unittest.main()
