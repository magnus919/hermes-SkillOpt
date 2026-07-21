# Local Installation After a Merged Skill Change

Use this after a repository-backed skill has merged and the user asks to install it for local Hermes discovery.

## Installation gate

1. Confirm the source contains `SKILL.md` at the merged commit and that its tracked `HEAD` matches `origin/main`.
2. Inspect the intended long-lived checkout before switching or pulling it. A directory named `*-main` is not proof that it is on `main`.
3. If that checkout contains an unrelated branch, tracked modifications, or untracked work, do not switch, reset, stash, or pull it as part of installation. Use an already-verified merged worktree, or create a dedicated clean worktree from `origin/main` when normal repository tooling is available.
4. Install the Agent Skill itself, not its optional service or CLI dependency. Prefer a symlink so upstream updates remain visible:

   ```bash
   ln -s /durable/checkout/<skill-name> ~/.hermes/skills/<skill-name>
   ```

5. Verify all three layers:
   - the symlink resolves to the intended durable source;
   - the installed `SKILL.md` and any bundled self-test are readable and pass;
   - `hermes skills list --source local` reports the exact skill as `enabled`.

## Pitfalls

- Do not infer checkout state from its directory name.
- Do not overwrite an existing destination; inspect whether it is a symlink, local copy, or hub-managed skill first.
- Do not link to a disposable validation candidate under `/tmp`.
- Do not disturb unrelated work merely to make a canonical checkout look clean.
- Keep private filesystem paths out of public skill documentation and PRs; use placeholders in reusable examples.
