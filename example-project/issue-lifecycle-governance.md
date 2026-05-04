# Issue / OpenSpec Lifecycle Governance

Every non-trivial user-reported problem should be tracked through a GitHub Issue. New capabilities, governance changes, security changes, architecture changes, and ambiguous work should also have an OpenSpec change before implementation.

Keep GitHub Issue, OpenSpec tasks, PR, and `.ai-memory` synchronized at meaningful transitions: accepted, planning, investigating, fixing, PR opened, validating, deployment decision, waiting confirmation, and closed.

AI must verify first, then ask whether to close the issue. Do not ask to close while verification is pending, TBD, not run, or 待驗證.

Close an issue only after the user or authorized maintainer explicitly confirms completion. The close comment should link the PR, verification evidence, deployment evidence when applicable, and rollback reference.
