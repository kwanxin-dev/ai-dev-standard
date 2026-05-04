## Why

User-reported problems are often scattered across chat, PRs, local memory, and ad hoc notes. The standard should make issue tracking, OpenSpec planning, progress synchronization, verification, completion confirmation, and closure a single repeatable lifecycle.

## What Changes

- Add an issue-backed lifecycle standard for non-trivial problem reports and governance changes.
- Require OpenSpec for new capabilities, governance changes, security changes, architecture changes, and ambiguous work.
- Require progress synchronization across GitHub Issue, OpenSpec tasks, PR, and `.ai-memory` when present.
- Require AI to verify first and include evidence before asking whether to close an issue.
- Add reusable issue lifecycle helper script and GitHub templates.

## Impact

- Affected specs: `delivery-governance`
- Affected files:
  - `AGENTS.md`
  - `github-project-lifecycle-sop.md`
  - `issue-lifecycle-governance.md`
  - `.github/ISSUE_TEMPLATE/*`
  - `.github/PULL_REQUEST_TEMPLATE.md`
  - `init-project.sh`
  - `init-project.ps1`
  - `example-project/`
  - `scripts/issue_lifecycle.sh`
