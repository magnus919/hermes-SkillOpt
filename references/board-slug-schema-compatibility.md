# Board-Slug Schema Compatibility

## Problem

The board metadata template historically requires `board_slug` to match `^SkillOpt-`, while the Hermes Kanban CLI accepts lowercase kebab-case slugs and existing SkillOpt boards use names such as `skillopt-fireflies`.

A run can therefore have a valid, addressable board and an invalid template-shaped metadata file. Do not rename a live board merely to satisfy a stale template regex.

## Preflight rule

1. Create or inspect the board with `hermes kanban boards list` and record its exact slug.
2. Use that exact slug in `board-metadata.json`.
3. Compare the template schema with the live CLI contract before asserting schema validity.
4. If they conflict, record the compatibility boundary in the preflight dossier and continue with the live CLI contract. Do not fabricate a conforming slug or silently omit the mismatch.

## Why this matters

The board slug is a routing key. A metadata-only normalization can point later commands at a nonexistent board, while a live-board rename can strand existing cards. The smallest correct fix is to preserve the real slug and make the mismatch explicit until the template is corrected upstream.
