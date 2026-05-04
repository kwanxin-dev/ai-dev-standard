## Context

The standard already says GitHub Issues are formal work units and `.ai-memory` is not a replacement. The missing standard is the complete lifecycle: issue intake, OpenSpec when needed, progress synchronization, verification before close prompt, explicit confirmation, and closure.

## Goals

- Make non-trivial problem reports issue-backed by default.
- Make OpenSpec the default planning mechanism for new capabilities and governance changes.
- Keep GitHub Issue, OpenSpec tasks, PR, and memory synchronized at meaningful transitions.
- Prevent premature issue closure by requiring completed verification evidence before asking to close.
- Provide reusable templates and scripts for new projects.

## Non-Goals

- Do not require OpenSpec for trivial fixes.
- Do not introduce GitHub Projects as a dependency.
- Do not close issues solely because CI passed or a PR merged.

## Decisions

- GitHub Issues remain the operational tracker.
- OpenSpec records durable behavior and implementation tasks for capability or governance changes.
- The close prompt is only allowed after verification evidence exists.
- `scripts/issue_lifecycle.sh` is a helper, not the only allowed path; the SOP remains the source of truth.
- `.ai-memory` records meaningful milestones append-only and does not mirror every issue comment.

## Risks / Trade-offs

- Risk: more process for small work.
  - Mitigation: trivial exceptions remain allowed.
- Risk: progress updates become noisy.
  - Mitigation: update only meaningful transitions.
- Risk: helper script misses a secret pattern.
  - Mitigation: script blocks common patterns, but no-secrets remains a human/AI review requirement.
