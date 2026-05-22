---
name: requirements-workflow-digest
description: Analyze reqs/PRD.md and update reqs/INTERPRETATION.md with current understanding, clear requirements, constraints, expansion areas, open questions, and change notes. Use when explicitly invoked with $requirements-workflow-digest.
---

# Requirements Workflow Digest

Digest `reqs/PRD.md` into `reqs/INTERPRETATION.md`.

## Resources

Read `../requirements-workflow-shared/references/conventions.md` before acting.

Use templates from `../requirements-workflow-shared/assets/templates/` only when creating a missing target is explicitly allowed by this skill.

## Preconditions

Require these files:

- `reqs/PRD.md`
- `reqs/CONSTITUTION.md`
- `reqs/WORKFLOW.md`
- `reqs/INTERPRETATION.md`

If any are missing, stop and tell the user which skill or manual action is needed. Do not create missing files except when the user explicitly asks.

## Workflow

1. Read the PRD, constitution, workflow status, and current interpretation.
2. Analyze the PRD for:
   - current understanding
   - clear requirements
   - constraints
   - areas for expansion
   - open questions needed to clarify unclear, missing, mismatched, or incompatible requirement detail
3. Update `INTERPRETATION.md` in place. Preserve useful existing content when it remains compatible with the latest PRD reading.
4. Keep a single `Open Questions` section. Use lightweight IDs such as `Q-001` when helpful.
5. Use neutral question wording. Do not create a separate issue category for mismatched source material.
6. Add a `Change Notes` entry when the digest materially changes requirement understanding.
7. Update generated status in `WORKFLOW.md`, including open question count and current phase. Do not alter acceptance checklist items.
8. Do not invoke another workflow skill automatically.

## Output

Report:

- changed files
- open question count
- the next appropriate skill, usually `$requirements-workflow-resolve` or `$requirements-workflow-spec`
