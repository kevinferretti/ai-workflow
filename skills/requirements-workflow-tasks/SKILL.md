---
name: requirements-workflow-tasks
description: Create or update reqs/TASKS.md as the active core implementation task list derived from reqs/PLAN.md. Use when explicitly invoked with $requirements-workflow-tasks after the core plan is accepted or the user requests a draft.
---

# Requirements Workflow Tasks

Create or update active core implementation tasks.

## Resources

Read `../requirements-workflow-shared/references/conventions.md` before acting.

Use `../requirements-workflow-shared/assets/templates/TASKS.md` when creating a new task list.

## Preconditions

Require these files:

- `reqs/CONSTITUTION.md`
- `reqs/WORKFLOW.md`
- `reqs/PLAN.md`

If any are missing, stop and report the missing files.

By default, require `PLAN accepted for tasking` to be checked in `WORKFLOW.md`. If it is unchecked and the user has not explicitly requested a draft anyway, stop and explain the gate.

## Workflow

1. Read the constitution, workflow status, and core implementation plan.
2. Create `TASKS.md` from the template if missing; otherwise read the existing task list before editing.
3. Generate actionable tasks for active core implementation only.
4. Include verification tasks that prove the implementation satisfies the plan.
5. Keep enhancement work out of `TASKS.md` unless the user explicitly activates that scope.
6. Update generated status in `WORKFLOW.md`. Do not alter acceptance checklist items.
7. Do not invoke another workflow skill automatically.

## Output

Report changed files, task count, verification coverage, and that `TASKS accepted for implementation` remains human-controlled.
