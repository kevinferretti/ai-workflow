---
name: requirements-workflow-enhancement-plan
description: Create or update reqs/ENHANCEMENT_PLAN.md for future expansion work derived from interpretation expansion areas and spec deferred scope. Use when explicitly invoked with $requirements-workflow-enhancement-plan.
---

# Requirements Workflow Enhancement Plan

Create or update future expansion planning.

## Resources

Read `../requirements-workflow-shared/references/conventions.md` before acting.

Use `../requirements-workflow-shared/assets/templates/ENHANCEMENT_PLAN.md` when creating a new enhancement plan.

## Preconditions

Require these files:

- `reqs/CONSTITUTION.md`
- `reqs/WORKFLOW.md`
- `reqs/INTERPRETATION.md`
- `reqs/SPEC.md`

If any are missing, stop and report the missing files.

By default, require `SPEC accepted for planning` to be checked in `WORKFLOW.md`. If it is unchecked and the user has not explicitly requested a draft anyway, stop and explain the gate.

## Workflow

1. Read the constitution, workflow status, interpretation, and spec.
2. Create `ENHANCEMENT_PLAN.md` from the template if missing; otherwise read the existing file before editing.
3. Base the plan on `INTERPRETATION.md` areas for expansion and `SPEC.md` deferred or non-goal scope.
4. Keep this separate from `PLAN.md` and `TASKS.md`.
5. Include candidate enhancements, prioritization, dependencies on core work, risks, and activation criteria.
6. Update generated status in `WORKFLOW.md`. Do not alter acceptance checklist items.
7. Do not invoke another workflow skill automatically.

## Output

Report changed files, the highest-priority expansion paths, and whether any expansion item would require updating interpretation before activation.
