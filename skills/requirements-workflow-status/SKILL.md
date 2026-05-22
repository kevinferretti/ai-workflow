---
name: requirements-workflow-status
description: Report the current markdown requirements workflow progress from reqs/ artifacts. Use when explicitly invoked with $requirements-workflow-status or when the user asks where the workflow stands.
---

# Requirements Workflow Status

Summarize workflow state without changing files by default.

## Resources

Read `../requirements-workflow-shared/references/conventions.md` before acting.

## Workflow

1. Inspect `reqs/` in the current repo.
2. Report which expected artifacts are present or missing.
3. Read `WORKFLOW.md` if present and summarize generated status plus acceptance checklist state.
4. Read `INTERPRETATION.md` if present and report open question count.
5. Report the next likely skill based on the current state.
6. Do not edit files unless the user explicitly asks to reconcile status.

## Output

Keep the status concise:

- current phase
- artifact presence
- acceptance checklist state
- open question count
- next recommended manual invocation
