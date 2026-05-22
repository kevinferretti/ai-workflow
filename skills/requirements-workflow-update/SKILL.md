---
name: requirements-workflow-update
description: Incorporate new stakeholder, product, or discovery information into reqs/INTERPRETATION.md and update workflow status. Use when explicitly invoked with $requirements-workflow-update and the user provides new requirement understanding.
---

# Requirements Workflow Update

Update the interpretation from new external requirement information.

## Resources

Read `../requirements-workflow-shared/references/conventions.md` before acting.

## Preconditions

Require these files:

- `reqs/CONSTITUTION.md`
- `reqs/WORKFLOW.md`
- `reqs/INTERPRETATION.md`

If any are missing, stop and tell the user to run `$requirements-workflow-init`.

Require new information from the user. If the user did not provide it, ask for the update and stop.

## Workflow

1. Read the constitution, workflow status, and current interpretation.
2. Identify which sections of `INTERPRETATION.md` the new information affects.
3. Update the interpretation directly when the impact is clear.
4. Add or revise open questions when the new information leaves a decision unresolved.
5. Append a `Change Notes` entry with the source context if provided.
6. Update generated status in `WORKFLOW.md`, including open question count and current phase.
7. Do not alter acceptance checklist items.
8. Do not invoke another workflow skill automatically.

## Output

Report changed files, the interpretation impact, remaining open question count, and the next appropriate skill.
