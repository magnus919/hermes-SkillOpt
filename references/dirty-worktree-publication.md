# Publishing a greenfield skill from a dirty checkout

Use this when a new skill was authored in a checkout that already has unrelated changes, is on a non-main branch, or contains generated graph output. The SkillOpt merge result must not inherit that checkout's accidental scope.

## Safe publication path

1. Keep the source checkout untouched. Identify the exact intended files: the skill directory plus only catalog/trigger/index files required by repository conventions.
2. Fetch the remote default branch, then create a fresh worktree and feature branch from it:

   ```sh
   git fetch origin main
   git worktree add -b fix/skillopt-<skill> /path/to/clean-worktree origin/main
   ```

3. Transfer only the identified skill files into the clean worktree. Reapply catalog and trigger additions against the fresh branch. Do not carry untracked generated output such as graph artifacts, unrelated edits, credentials, or local deployment files.
4. Run the repository validator, the skill's script/tests, `git diff --check`, and the integration-boundary check from the clean worktree.
5. Reconcile every rollout, validation, and review result before staging. Stage only the intended paths; inspect `git diff --cached --name-only` and a privacy scan before committing.
6. File the required issue when repository policy calls for one, then open a focused PR with validation evidence and meaningful AI-assistance disclosure. Do not merge without review.

## Why this matters

A clean worktree turns the branch boundary into a verification gate. It prevents a valid SkillOpt candidate from being published alongside unrelated work just because both happened to exist in the same checkout.
