#!/usr/bin/env python3
"""Verify a skill directory as a tree, not a document.

A skill's `SKILL.md` index links to reference files that are loaded on demand.
An edit that renames, moves, or forgets one leaves a link that resolves to
nothing; the skill still loads and silently loses the procedure it claims to
defer to.

Only two things count as links, because everything else in a skill document is
prose illustration:

* markdown link targets: ``[label](references/foo.md)``
* paths listed in the `## References` table of `SKILL.md`, which this
  repository writes as backticked paths rather than links

Illustrative paths inside pitfall text (a worked example from another skill, a
placeholder artifact path) are deliberately not checked.

Usage:
    python3 scripts/check_skill_tree.py [--root PATH] [--strict]

Exit codes: 0 clean, 1 missing link (or orphans with --strict).
Standard library only; Python 3.8+.
"""

from __future__ import annotations

import argparse
from pathlib import Path
import re
import sys


LINK_RE = re.compile(r"\]\((\.\.?/[^)\s]+|[A-Za-z0-9_][^)\s:]*)\)")
TABLE_PATH_RE = re.compile(r"`((?:references|scripts|templates|assets)/[A-Za-z0-9_.\-/]+)`")
SCAN_GLOBS = ("SKILL.md", "AGENTS.md", "README.md", "TESTING.md", "references/*.md")


def _files(root):
    found = []
    for pattern in SCAN_GLOBS:
        found.extend(sorted(root.glob(pattern)))
    return found


# Sections whose backticked paths are an index of real files, not prose
# illustration: the skill's References table and the agent guide's Key Files.
INDEX_SECTIONS = {"SKILL.md": "## References", "AGENTS.md": "## Key Files"}


def _index_links(text, heading):
    """Paths named in an index section (this repo's backtick convention)."""
    if heading not in text:
        return set()
    section = text.split(heading, 1)[1]
    if "\n## " in section:
        section = section.split("\n## ", 1)[0]
    return set(TABLE_PATH_RE.findall(section))


def check_tree(root):
    root = Path(root).resolve()
    missing = []
    referenced = set()

    for path in _files(root):
        text = path.read_text(encoding="utf-8", errors="replace")

        targets = set(LINK_RE.findall(text))
        if path.name in INDEX_SECTIONS:
            # Index paths are written relative to the skill root.
            for entry in _index_links(text, INDEX_SECTIONS[path.name]):
                target = (root / entry).resolve()
                if target.is_file():
                    referenced.add(target)
                else:
                    missing.append((path, entry, "no such file (index section)"))
            targets = {t for t in targets if not t.startswith("../")}

        for target_text in sorted(targets):
            if target_text.startswith(("http://", "https://", "mailto:")):
                continue
            target = (path.parent / target_text).resolve()
            if not target.is_file():
                missing.append((path, target_text, "no such file"))
                continue
            referenced.add(target)

    references_dir = root / "references"
    orphans = []
    if references_dir.is_dir():
        for candidate in sorted(references_dir.rglob("*.md")):
            if candidate.resolve() not in referenced:
                orphans.append(candidate)

    return missing, orphans


def main(argv=None):
    parser = argparse.ArgumentParser(description="Verify skill-tree link integrity.")
    parser.add_argument("--root", default=None)
    parser.add_argument("--strict", action="store_true",
                        help="treat unreferenced reference files as failures")
    args = parser.parse_args(argv)

    root = Path(args.root) if args.root else Path(__file__).resolve().parents[1]
    missing, orphans = check_tree(root)

    for path, target, reason in missing:
        print("MISSING  %s -> %s (%s)" % (path.relative_to(root), target, reason))
    for orphan in orphans:
        print("ORPHAN   %s (never referenced)" % orphan.relative_to(root))

    if missing:
        print("\n%d broken link(s)." % len(missing))
        return 1
    if orphans and args.strict:
        print("\n%d unreferenced reference file(s)." % len(orphans))
        return 1

    print("Skill tree clean: all links resolve%s."
          % ("" if not orphans else " (%d advisory orphan(s))" % len(orphans)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
