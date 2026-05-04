# OpenSpec Instructions

Use OpenSpec for new capabilities, governance changes, security changes, architecture changes, and ambiguous work.

Workflow:
1. Create `openspec/changes/<change-id>/proposal.md`.
2. Add `tasks.md`, optional `design.md`, and spec deltas under `specs/<capability>/spec.md`.
3. Run `openspec validate <change-id> --strict`.
4. Sync GitHub Issue, OpenSpec tasks, PR, and `.ai-memory` progress until confirmed closure.
