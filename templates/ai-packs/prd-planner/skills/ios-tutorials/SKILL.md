---
name: ios-tutorials
description: Build an iOS project tutorial from the code and documentation that actually exist in the current repository, with verified steps and explicit gaps.
license: MIT
metadata:
  author: Oscar Canton
  origin: first-party
---

# iOS Project Tutorials

Use this skill when someone needs a guided explanation of the current iOS codebase. It does not depend on, search for, or promise a global tutorial catalogue.

## Source boundary

Work only from material available to the task: repository instructions, source, project manifests, tests, fixtures, and existing documentation. If a required module or private service is unavailable, state the gap and design the lesson around the visible contract.

## Tutorial workflow

1. Ask what the reader should be able to do at the end.
2. Verify the project target, Swift mode, minimum OS, and test framework.
3. Trace one concrete path from entry point to visible outcome.
4. Select the smallest set of files needed to explain that path.
5. Break the lesson into checkpoints that compile or test independently.
6. Run every command and validate every code reference against the current tree.
7. End with a practical exercise and an objective completion check.

## Required structure

- **Outcome:** one observable capability.
- **Prerequisites:** tools, target, and concepts actually needed.
- **System map:** the relevant modules and dependency direction.
- **Walkthrough:** short steps with a reason, action, and verification signal.
- **Failure clinic:** likely errors grounded in this repository.
- **Exercise:** a bounded change that does not require hidden infrastructure.
- **Completion check:** build, test, or behavior that proves the outcome.
- **Further reading:** local source and documentation paths only.

## Rules

Do not invent filenames, APIs, architecture layers, or commands. Do not paste large production files; quote the minimum necessary and link to the source. Mark inferred intent as inference. Keep generated documentation free of secrets, internal endpoints, and personal data.

When the code and docs disagree, report the discrepancy and treat executable behavior plus tests as the current implementation—not as proof that the implementation is intended.
