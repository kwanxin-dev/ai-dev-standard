## ADDED Requirements

### Requirement: Issue-Backed Problem Lifecycle

The standard SHALL require every non-trivial user-reported problem to be tracked through a GitHub Issue from intake to confirmed closure.

#### Scenario: New problem intake

- **WHEN** a user reports a bug, regression, operational blocker, or governance problem that needs investigation, code changes, verification, deployment checks, or follow-up
- **THEN** the AI or maintainer SHALL search open GitHub Issues for the same symptom, affected page/API/workflow, error message, or related OpenSpec change
- **AND** if no matching open issue exists, the AI or maintainer SHALL create a new GitHub Issue
- **AND** issue content SHALL exclude passwords, tokens, SSH private keys, raw credential values, and sensitive production data

#### Scenario: Duplicate report reuse

- **GIVEN** a matching open GitHub Issue exists
- **WHEN** new evidence or work begins
- **THEN** the AI or maintainer SHALL update the existing issue instead of creating a duplicate

### Requirement: OpenSpec-Governed Change Planning

The standard SHALL require OpenSpec for new capabilities, governance changes, security changes, architecture changes, and ambiguous work that needs durable planning before implementation.

#### Scenario: Governance change begins

- **WHEN** a task changes delivery, issue, PR, OpenSpec, memory, security, or architecture governance
- **THEN** the AI or maintainer SHALL create or update an OpenSpec change before implementation
- **AND** the OpenSpec change SHALL link the GitHub Issue

### Requirement: Cross-Tracker Progress Synchronization

The standard SHALL require meaningful progress transitions to be synchronized across GitHub Issue, OpenSpec tasks, PR, and `.ai-memory` when memory is present.

#### Scenario: PR opened

- **GIVEN** an issue and OpenSpec change track the work
- **WHEN** a PR is opened
- **THEN** the PR SHALL link the issue and OpenSpec change
- **AND** the issue SHALL be updated with branch, PR, current verification state, and next action
- **AND** OpenSpec tasks SHALL reflect completed and pending work

#### Scenario: Validation completed

- **WHEN** verification is completed
- **THEN** the issue and PR SHALL record commands, results, preview/smoke/deploy evidence when applicable, and rollback reference
- **AND** `.ai-memory` SHALL record meaningful milestones append-only when present

### Requirement: Verification Before Close Prompt

The standard SHALL prohibit asking to close an issue until verification has been completed and evidence is available.

#### Scenario: Closeout reached after verification

- **GIVEN** a fix or governance change has been implemented
- **WHEN** completed verification evidence is available
- **THEN** the AI or maintainer MAY ask the user or authorized maintainer whether the issue is complete and should be closed
- **AND** the prompt SHALL include or link verification evidence

#### Scenario: Closeout reached before verification

- **GIVEN** verification is pending, not run, TBD, or otherwise incomplete
- **WHEN** closeout is considered
- **THEN** the AI or maintainer SHALL NOT ask whether to close the issue
- **AND** the issue SHALL remain open with the next verification action

### Requirement: Confirmed Issue Closure

The standard SHALL require explicit user or authorized maintainer confirmation before closing an issue.

#### Scenario: Completion confirmed

- **GIVEN** verification evidence exists
- **AND** the user or authorized maintainer explicitly confirms completion
- **WHEN** the issue is closed
- **THEN** the close comment SHALL link the PR, verification evidence, deployment evidence when applicable, and rollback reference

#### Scenario: Completion not confirmed

- **GIVEN** verification evidence exists
- **WHEN** no explicit completion confirmation is available
- **THEN** the issue SHALL remain open in waiting-confirmation state
