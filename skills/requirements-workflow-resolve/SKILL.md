---
name: requirements-workflow-resolve
description: Resolve or route open questions in reqs/INTERPRETATION.md one at a time, including moving spec-owned questions to reqs/SPEC.md when the user identifies them as spec questions. Use when explicitly invoked with $requirements-workflow-resolve.
---

# Requirements Workflow Resolve

Ask, resolve, or route open interpretation questions one at a time.

## Resources

Read `../requirements-workflow-shared/references/conventions.md` before acting.

Use `../requirements-workflow-shared/assets/templates/SPEC.md` if `SPEC.md` is missing and a question must be routed there.

## Preconditions

Require these files:

- `reqs/CONSTITUTION.md`
- `reqs/WORKFLOW.md`
- `reqs/INTERPRETATION.md`

If any are missing, stop and tell the user to run `$requirements-workflow-init`.

## Workflow

1. Read `INTERPRETATION.md` and find unresolved questions in the `Open Questions` section.
2. If the user supplied an answer to a specific question, apply that answer first.
3. If the user says the current question belongs in `SPEC.md`, is a spec question, or is not an interpretation question:
   - read `SPEC.md`, creating it from the shared template if missing
   - move the question out of `INTERPRETATION.md`
   - add the question to `SPEC.md` under `Open Spec Questions`
   - preserve the question ID and wording when practical
   - add a short note that it was moved from `INTERPRETATION.md`
   - do not answer, reinterpret, or expand the question unless the user also supplied the answer
   - add a `Change Notes` entry because workflow ownership changed
   - update generated status in `WORKFLOW.md`
   - do not alter acceptance checklist items
4. When applying an answer:
   - update the relevant interpretation sections
   - remove or mark the answered question as resolved
   - add a `Change Notes` entry when requirement understanding changed
   - update generated status in `WORKFLOW.md`
   - do not alter acceptance checklist items
5. If unresolved interpretation questions remain, ask exactly one next question and stop.
6. If no unresolved interpretation questions remain, report that the interpretation has no open questions and identify the next likely skill.

## Question Selection

Prefer questions that affect core scope before questions that only affect future expansion, but do not create separate question categories in the artifact.

Ask concise questions. Include why the answer matters when that is not obvious.
