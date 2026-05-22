---
name: requirements-workflow-plan
description: Create or update reqs/PLAN.md as the core implementation plan derived from reqs/SPEC.md. Use when explicitly invoked with $requirements-workflow-plan after the spec is accepted or the user requests a draft.
---

# Requirements Workflow Plan

Create or update the core implementation plan.

## Resources

Read `../requirements-workflow-shared/references/conventions.md` before acting.

Use `../requirements-workflow-shared/assets/templates/PLAN.md` when creating a new plan.

## Preconditions

Require these files:

- `reqs/CONSTITUTION.md`
- `reqs/WORKFLOW.md`
- `reqs/SPEC.md`

If any are missing, stop and report the missing files.

By default, require `SPEC accepted for planning` to be checked in `WORKFLOW.md`. If it is unchecked and the user has not explicitly requested a draft anyway, stop and explain the gate.

## Workflow

1. Read the constitution, workflow status, and spec.
2. Create `PLAN.md` from the template if missing; otherwise read the existing plan before editing.
3. Produce a core implementation plan only. Keep future expansion out of this file.
4. Include summary, assumptions, approach, milestones, risks, verification, and out-of-scope items.
5. If planning reveals missing requirement detail, stop and tell the user to update `INTERPRETATION.md` before changing the plan.
6. Update generated status in `WORKFLOW.md`. Do not alter acceptance checklist items.
7. Do not invoke another workflow skill automatically.

## Output

Report changed files, planning assumptions, and that `PLAN accepted for tasking` remains human-controlled.
