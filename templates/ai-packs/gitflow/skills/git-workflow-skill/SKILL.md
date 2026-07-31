---
name: git-workflow-skill
description: Plan and execute safe Git workflows that respect repository instructions, branch policy, review boundaries, and release history.
license: MIT
metadata:
  author: Oscar Canton
  origin: first-party
---

# Git Workflow

Use this skill when a task includes branching, commits, integration, release preparation, or recovery from a Git mistake.

## Operating contract

1. Read the repository instructions before choosing a workflow.
2. Inspect `status`, the current branch, remotes, and recent history before changing anything.
3. Treat uncommitted work as belonging to the user. Never discard or absorb unrelated changes.
4. Stage explicit paths and review the staged diff before every commit.
5. Keep commits small, coherent, and independently testable.
6. Do not push, merge, rebase shared history, tag, or publish unless the user authorized that exact action.
7. Never add an automated co-author line.

## Branch selection

Repository-specific instructions win. When the repository follows Gitflow:

- branch `feature/<topic>` from `develop` for product work;
- branch `release/<version>` from `develop`, then integrate it into `main` and `develop`;
- branch `hotfix/<topic>` from `main`, then integrate it into `main` and `develop`;
- keep `main` deployable and use semantic version tags only for releases.

If the repository does not declare a strategy, propose the smallest reversible branch plan and wait for approval before creating shared history.

## Commit workflow

For each logical change:

1. Run the narrowest relevant tests.
2. Inspect `git diff --check` and the unstaged diff.
3. Stage only the intended paths.
4. Inspect `git diff --cached`.
5. Commit with an imperative Conventional Commit subject such as `fix(scope): protect existing files`.
6. Re-run the relevant validation if hooks or formatting changed the tree.

Split changes by responsibility: behavior, tests, documentation, generated artifacts, and dependency updates should only share a commit when they form one inseparable unit.

## Integration checks

Before a merge or rebase, confirm:

- the target branch is correct and current;
- the working tree contains no unrelated staged files;
- required tests pass on the source branch;
- conflicts are resolved by understanding both sides, not by selecting one side wholesale;
- the resulting history matches the repository policy.

After integration, verify the final commit graph, branch pointers, and remote state. A local merge is not evidence that a remote branch changed.

## Recovery

Prefer additive and recoverable operations. Use a new corrective commit for published history. Use `git reflog` to locate lost local commits. Never run destructive reset, clean, or force-push commands without explicit authorization and an exact target.

## Completion report

Report the branch, commits created, validation run, remaining uncommitted files, and whether any remote state changed.
