# Issue / OpenSpec Lifecycle Governance

> Goal: every non-trivial user-reported problem is tracked from intake to confirmed closure through GitHub Issues, OpenSpec, PRs, verification evidence, and append-only memory.

## When To Open Or Reuse An Issue

Create or reuse a GitHub Issue when a user report needs investigation, code changes, production or staging checks, follow-up, or handoff. A quick answer, typo-only fix, formatting-only change, or one-line trivial correction may be documented as a trivial exception.

Before creating a new issue, search open issues by symptom, affected page/API/workflow, error message, and related OpenSpec change. Reuse the matching open issue when one exists.

## When To Open OpenSpec

Open an OpenSpec change before implementation when the work adds a capability, changes governance, affects architecture, changes security or delivery workflow, or is ambiguous enough that a durable proposal is safer than direct coding.

Bug fixes that restore already-defined behavior can skip OpenSpec, but they still need an issue when they are non-trivial.

## Required Progress Sync

At every meaningful transition, sync the same state across GitHub Issue, OpenSpec tasks, PR, and `.ai-memory` when the project uses memory:

| Transition | Required update |
| --- | --- |
| accepted | issue created/reused, duplicate search noted |
| planning | OpenSpec change linked, scope and non-goals recorded |
| investigating | current finding, branch, next action |
| fixing | implementation direction and changed area |
| pr-opened | PR link, issue/milestone, OpenSpec change |
| validating | command, result, preview/smoke/deploy evidence |
| waiting-confirmation | completed verification evidence plus close prompt |
| closed | confirmation actor, PR, verification, rollback reference |

## Closeout Rule

AI must verify first, then ask whether to close.

The close prompt is allowed only after completed verification evidence exists. Do not ask to close with `pending`, `TBD`, `not run`, `待驗證`, or similar unresolved verification text.

Use this exact prompt style:

```text
#<issue> 是否已完成，是否要關閉 issue？
```

Only close the issue after the user or authorized maintainer explicitly confirms completion.

## No-Secrets Rule

Issue bodies, issue comments, PRs, OpenSpec files, docs, and `.ai-memory` records must not contain passwords, tokens, SSH private keys, raw credential values, or sensitive production data. Redact values and describe the evidence source instead.

## Helper Script

Use `scripts/issue_lifecycle.sh` when available:

```bash
scripts/issue_lifecycle.sh search --query "<symptom/page/error>"
scripts/issue_lifecycle.sh create --title "<title>" --summary "<summary>" --area "<area>" --observed "<observed>" --next-action "<next>"
scripts/issue_lifecycle.sh update --issue <number> --status pr-opened --summary "<summary>" --pr "PR #<number>" --next-action "<next>"
scripts/issue_lifecycle.sh request-close --issue <number> --summary "<summary>" --verification "<completed evidence>" --pr "PR #<number>"
scripts/issue_lifecycle.sh close --issue <number> --summary "<summary>" --verification "<completed evidence>" --pr "PR #<number>" --rollback "<rollback>" --confirmed-by "<name>" --confirmation-note "<note>"
```

`request-close` only posts a waiting-confirmation comment. `close` requires explicit confirmation metadata and closes the issue.
