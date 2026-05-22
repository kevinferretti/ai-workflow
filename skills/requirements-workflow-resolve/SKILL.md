---
name: requirements-workflow-resolve
description: Resolve open questions in reqs/INTERPRETATION.md one at a time and update the interpretation after each answer. Use when explicitly invoked with $requirements-workflow-resolve.
---

# Requirements Workflow Resolve

Ask and resolve open interpretation questions one at a time.

## Resources

Read `../requirements-workflow-shared/references/conventions.md` before acting.

## Preconditions

Require these files:

- `reqs/CONSTITUTION.md`
- `reqs/WORKFLOW.md`
- `reqs/INTERPRETATION.md`

If any are missing, stop and tell the user to run `$requirements-workflow-init`.

## Workflow

1. Read `INTERPRETATION.md` and find unresolved questions in the `Open Questions` section.
2. If the user supplied an answer to a specific question, apply that answer first.
3. When applying an answer:
   - update the relevant interpretation sections
   - remove or mark the answered question as resolved
   - add a `Change Notes` entry when requirement understanding changed
   - update generated status in `WORKFLOW.md`
   - do not alter acceptance checklist items
4. If unresolved questions remain, ask exactly one next question and stop.
5. If no unresolved questions remain, report that the interpretation has no open questions and identify the next likely skill.

## Question Selection

Prefer questions that affect core scope before questions that only affect future expansion, but do not create separate question categories in the artifact.

Ask concise questions. Include why the answer matters when that is not obvious.
