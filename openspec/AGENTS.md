# OpenSpec Instructions

Use OpenSpec when a task introduces a capability, changes delivery/security/governance behavior, changes architecture, or is ambiguous enough to need an approved plan before implementation.

## Workflow

1. Read `openspec/project.md`.
2. Run `openspec list` and `openspec list --specs` when the CLI is available.
3. Create a verb-led change id, for example `add-issue-lifecycle-governance`.
4. Add `proposal.md`, `tasks.md`, optional `design.md`, and spec deltas under `openspec/changes/<change-id>/specs/<capability>/spec.md`.
5. Write deltas with `## ADDED|MODIFIED|REMOVED Requirements` and at least one `#### Scenario:` per requirement.
6. Run `openspec validate <change-id> --strict` before PR.
7. Keep OpenSpec tasks synchronized with the GitHub Issue and PR until closeout.

## Issue Lifecycle Coupling

For non-trivial work, every OpenSpec change must link a GitHub Issue. The issue remains the operational tracker; OpenSpec records the proposed behavior and checklist.

Before asking to close the issue, verify first and add the verification evidence to both the issue and PR. Only close the issue after explicit user or maintainer confirmation.
