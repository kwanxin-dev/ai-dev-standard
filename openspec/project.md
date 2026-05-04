# Project Context

## Purpose

`ai-dev-standard` provides reusable AI development governance files for new and existing projects.

## Conventions

- `AGENTS.md` is the shared source of truth for all AI tools.
- Tool-specific files may add workflow details but must not weaken `AGENTS.md`.
- GitHub Issues are operational work trackers.
- OpenSpec changes are used for new capabilities, governance changes, security changes, architecture changes, and ambiguous work.
- `.ai-memory` is append-only project memory when present; it does not replace GitHub Issues.

## Verification

- Validate OpenSpec changes with `openspec validate <change-id> --strict`.
- Validate shell scripts with `bash -n`.
- Validate generated GitHub issue/PR templates by reading the rendered YAML/Markdown structure.
