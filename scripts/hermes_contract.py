#!/usr/bin/env python3
"""Hermes CLI contract: keep documented commands honest.

SkillOpt tells agents to run specific ``hermes`` commands. Hermes renames and
retires CLI surfaces over time (``hermes oneshot`` became the global ``-z``
flag). Without a machine check, documentation rots silently because the
repository's CI has no Hermes installation.

This module provides:

* ``parse_help`` -- extract subcommands and flags from a ``--help`` capture.
* ``build_manifest`` -- probe a live Hermes install for exactly the command
  paths the documentation cites, producing a small checked-in manifest.
* ``extract_citations`` -- find ``hermes ...`` command citations in the docs.
* ``resolve`` -- decide whether one citation is valid against a manifest.

The manifest is the contract CI enforces. Refreshing it is a deliberate,
reviewable act:

    python3 scripts/hermes_contract.py --refresh

``--verify-live`` re-probes the installed CLI and fails when the manifest has
drifted, which is the local gate before a release.

Standard library only; Python 3.8+.
"""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import re
import shlex
import subprocess
import sys


SCHEMA_VERSION = 1
MANIFEST_RELPATH = "contracts/hermes-cli-contract.json"
DOC_GLOBS = ("*.md", "references/*.md")
UNIVERSAL_FLAGS = ("-h", "--help")


# --------------------------------------------------------------------------
# Help parsing
# --------------------------------------------------------------------------

_OPTION_RE = re.compile(r"(?<![\w-])(--[a-z0-9][a-z0-9-]*)(?![\w-])")
_SHORT_OPTION_RE = re.compile(r"(?<![\w-])(-[a-zA-Z])(?![\w-])")
_BRACE_GROUP_RE = re.compile(r"\{([a-z0-9_,.\- ]+)\}")
_POSITIONAL_RE = re.compile(r"^ {2,6}([a-z][a-z0-9-]*)(?:\s*\([^)]*\))?\s{2,}\S")


def parse_help(text):
    """Return ``{"flags": [...], "subcommands": [...]}`` for one ``--help`` capture.

    Subcommands are read from both usage brace groups (``{list,show}``) and the
    positional-arguments listing, because the top-level help uses the latter
    shape while most subcommands use the former.
    """
    flags = set()
    subcommands = set()

    # Global flags often appear only in the usage synopsis, so read that block
    # as well as the options listing.
    usage_lines = []
    collecting = False
    for line in text.splitlines():
        if line.startswith("usage:"):
            collecting = True
        elif collecting and not line.strip():
            collecting = False
        if collecting:
            usage_lines.append(line)
    usage_text = "\n".join(usage_lines)
    for flag in _OPTION_RE.findall(usage_text):
        flags.add(flag)
    for flag in _SHORT_OPTION_RE.findall(usage_text):
        flags.add(flag)

    for line in text.splitlines():
        stripped = line.strip()
        if not stripped.startswith("-"):
            continue
        for flag in _OPTION_RE.findall(stripped):
            flags.add(flag)
        for flag in _SHORT_OPTION_RE.findall(stripped):
            flags.add(flag)

    for group in _BRACE_GROUP_RE.findall(text):
        for token in group.split(","):
            token = token.strip()
            if token and re.fullmatch(r"[a-z][a-z0-9-]*", token):
                subcommands.add(token)

    in_positionals = False
    for line in text.splitlines():
        if re.match(r"^positional arguments:", line.strip()):
            in_positionals = True
            continue
        if in_positionals:
            if not line.strip():
                in_positionals = False
                continue
            match = _POSITIONAL_RE.match(line)
            if match:
                subcommands.add(match.group(1))

    return {
        "flags": sorted(flags),
        "subcommands": sorted(subcommands),
    }


# --------------------------------------------------------------------------
# Citations
# --------------------------------------------------------------------------

_FENCE_RE = re.compile(r"```[a-zA-Z0-9_-]*\n(.*?)```", re.DOTALL)
_INLINE_RE = re.compile(r"`([^`\n]+)`")


def _document_command_strings(text):
    """Yield candidate command strings from inline code spans and fenced blocks."""
    for block in _FENCE_RE.findall(text):
        for line in block.splitlines():
            line = line.strip()
            if line.startswith("$ "):
                line = line[2:].strip()
            if line.startswith("hermes "):
                yield line

    for span in _INLINE_RE.findall(text):
        span = span.strip()
        if span.startswith("$ "):
            span = span[2:].strip()
        if span.startswith("hermes "):
            yield span


def _tokenize(command):
    try:
        return shlex.split(command, comments=False, posix=True)
    except ValueError:
        return command.split()


def parse_citation(command):
    """Split one cited command into ``{"tokens", "raw"}``.

    Flags may appear before or after subcommands (``hermes kanban --board x
    list``), so tokens stay in order and ``resolve`` walks them against the
    manifest. Keeping citation parsing manifest-free means a doc edit cannot
    change how the gate reads the docs.
    """
    tokens = _tokenize(command)
    if not tokens or tokens[0] != "hermes" or len(tokens) == 1:
        return None
    remainder = tokens[1:]
    # Prose placeholders such as `hermes ...` describe the surface generically
    # and name no checkable command.
    if remainder[0].strip(".") == "":
        return None
    return {"tokens": remainder, "raw": command}


# Flags whose following token is a value rather than CLI surface. Used so
# ``hermes -z 'prompt'`` does not treat the prompt as a command name.
_VALUE_FLAGS = frozenset({
    "-z", "--oneshot", "-m", "--model", "--provider", "--reasoning", "-t",
    "--skills", "-s", "--resume", "--in", "--board", "--source", "--format",
    "--output", "--title", "--body", "--parent", "--workspace", "--branch",
    "--project", "--tenant", "--priority", "--max-runtime", "--created-by",
    "--max-retries", "--completion-contract", "--idempotency-key", "--worker",
    "--verifier", "--synthesizer", "--assignee", "--goal", "--session",
    "--limit", "--name", "--path", "--profile", "--since", "--until",
})


def extract_citations(repo_root):
    """Return sorted unique citations found across the documentation set."""
    seen = {}
    for pattern in DOC_GLOBS:
        for path in sorted(Path(repo_root).glob(pattern)):
            if not path.is_file():
                continue
            text = path.read_text(encoding="utf-8")
            for command in _document_command_strings(text):
                parsed = parse_citation(command)
                if not parsed:
                    continue
                key = tuple(parsed["tokens"])
                seen.setdefault(key, parsed)
    return [seen[key] for key in sorted(seen)]


# --------------------------------------------------------------------------
# Manifest
# --------------------------------------------------------------------------

def _run_help(hermes, path):
    argv = [hermes]
    argv.extend(path)
    argv.append("--help")
    result = subprocess.run(
        argv,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        universal_newlines=True,
    )
    return result.stdout or ""


def hermes_version(hermes):
    try:
        result = subprocess.run(
            [hermes, "--version"],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            universal_newlines=True,
        )
    except OSError:
        return "unknown"
    first = (result.stdout or "").strip().splitlines()
    return first[0] if first else "unknown"


def _live_paths(hermes, citations):
    """Resolve cited token streams against the live CLI, keeping real paths only.

    Retired verbs simply produce no path, which is what makes ``resolve`` fail
    on them later instead of silently blessing them.
    """
    root = parse_help(_run_help(hermes, []))
    known = {"flags": set(root["flags"]), "subcommands": set(root["subcommands"])}
    paths = []
    probed = {}

    for citation in citations:
        path = []
        current = known
        skip_next = False
        for token in citation["tokens"]:
            if skip_next:
                skip_next = False
                continue
            if token.startswith("-"):
                skip_next = token in _VALUE_FLAGS
                continue
            if token not in current["subcommands"]:
                break
            path.append(token)
            key = tuple(path)
            if key not in probed:
                probed[key] = parse_help(_run_help(hermes, list(path)))
            current = {
                "flags": current["flags"] | set(probed[key]["flags"]),
                "subcommands": set(probed[key]["subcommands"]),
            }
        if path:
            paths.append(path)

    return paths, probed


def build_manifest(hermes, citations, version=None, generated_at=None):
    """Probe ``hermes`` for exactly the command paths the documentation cites."""
    manifest = {
        "schema": SCHEMA_VERSION,
        "generated_at": generated_at,
        "hermes_version": version or hermes_version(hermes),
        "global_flags": parse_help(_run_help(hermes, []))["flags"],
        "commands": {},
    }

    paths, probed = _live_paths(hermes, citations)
    for path in paths:
        node = manifest["commands"]
        for depth, name in enumerate(path):
            entry = node.setdefault(name, {"flags": [], "subcommands": {}})
            if depth == len(path) - 1:
                entry["flags"] = sorted(set(entry["flags"]) | set(probed[tuple(path)]["flags"]))
            node = entry["subcommands"]

    return manifest


def load_manifest(repo_root):
    path = Path(repo_root) / MANIFEST_RELPATH
    return json.loads(path.read_text(encoding="utf-8"))


def resolve(manifest, citation):
    """Return ``None`` when the citation is valid, else an actionable reason.

    Walks the token stream the way the shell would: flags may appear at any
    level (``hermes kanban --board x list``), and the first positional that is
    not a known subcommand ends CLI-surface validation because everything after
    it is an argument value.
    """
    node = {
        "flags": set(manifest.get("global_flags", [])) | set(UNIVERSAL_FLAGS),
        "subcommands": manifest.get("commands", {}),
    }
    path = []

    index = 0
    tokens = citation["tokens"]
    while index < len(tokens):
        token = tokens[index]

        if token in ("|", "&&", ";", "||"):
            break

        if token.startswith("-"):
            if token in UNIVERSAL_FLAGS:
                index += 1
                continue
            if token not in node["flags"]:
                context = "hermes" + (" " + " ".join(path) if path else "")
                return "unknown flag(s) for '%s': %s" % (context, token)
            index += 2 if token in _VALUE_FLAGS else 1
            continue

        subcommands = node["subcommands"]
        if token in subcommands:
            path.append(token)
            entry = subcommands[token]
            node = {
                "flags": node["flags"] | set(entry.get("flags", [])),
                "subcommands": entry.get("subcommands", {}),
            }
            index += 1
            continue

        if not path:
            available = ", ".join(sorted(subcommands)) or "(none recorded)"
            return "'%s' is not a subcommand of 'hermes'; known: %s" % (token, available)
        break

    return None


# --------------------------------------------------------------------------
# CLI
# --------------------------------------------------------------------------

def _repo_root():
    return Path(__file__).resolve().parents[1]


def main(argv=None):
    parser = argparse.ArgumentParser(description="Verify documented Hermes CLI commands.")
    parser.add_argument("--refresh", action="store_true",
                        help="re-probe the installed Hermes and rewrite the manifest")
    parser.add_argument("--verify-live", action="store_true",
                        help="fail if the manifest differs from the installed Hermes")
    parser.add_argument("--check-docs", action="store_true",
                        help="fail if any documented citation is invalid (default)")
    parser.add_argument("--hermes", default=os.environ.get("HERMES", "hermes"),
                        help="hermes executable to probe (default: hermes)")
    parser.add_argument("--repo-root", default=None)
    args = parser.parse_args(argv)

    repo_root = Path(args.repo_root) if args.repo_root else _repo_root()
    citations = extract_citations(repo_root)

    if args.refresh:
        manifest = build_manifest(args.hermes, citations,
                                  generated_at=_today())
        target = repo_root / MANIFEST_RELPATH
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n",
                          encoding="utf-8")
        print("Wrote %s (%d command paths)" % (target, len(manifest["commands"])))
        return 0

    manifest = load_manifest(repo_root)

    if args.verify_live:
        live = build_manifest(args.hermes, citations,
                              generated_at=manifest.get("generated_at"))
        if live != manifest:
            print("Hermes CLI contract has drifted from %s." % MANIFEST_RELPATH)
            print("Refresh with: python3 scripts/hermes_contract.py --refresh")
            for key in sorted(set(live) | set(manifest)):
                if live.get(key) != manifest.get(key):
                    print("  changed: %s" % key)
            return 1
        print("Hermes CLI contract matches the installed CLI (%s)."
              % manifest.get("hermes_version"))
        return 0

    failures = 0
    for citation in citations:
        reason = resolve(manifest, citation)
        if reason:
            failures += 1
            print("FAIL  %s\n      %s" % (citation["raw"], reason))
    if failures:
        print("\n%d documented command(s) do not exist in the %s contract."
              % (failures, manifest.get("hermes_version")))
        print("Fix the documentation or refresh with: python3 scripts/hermes_contract.py --refresh")
        return 1
    print("All %d documented Hermes commands resolve." % len(citations))
    return 0


def _today():
    import datetime
    return datetime.date.today().isoformat()


if __name__ == "__main__":
    sys.exit(main())
