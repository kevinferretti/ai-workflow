---
name: requirements-workflow-init
description: Initialize the repo-local markdown requirements workflow under reqs/ by creating all shared workflow artifacts. Use when explicitly invoked with $requirements-workflow-init or when the user asks to set up the requirements workflow files for a repo.
---

# Requirements Workflow Init

Create the project-local requirements workflow scaffold.

## Resources

Read `../requirements-workflow-shared/references/conventions.md` before acting.

Use templates from `../requirements-workflow-shared/assets/templates/`.

## Workflow

1. Treat the current working directory as the repo root unless the user gives another path.
2. Create `reqs/` if it does not exist.
3. Create these shared workflow files from templates if missing:
   - `reqs/CONSTITUTION.md`
   - `reqs/WORKFLOW.md`
   - `reqs/INTERPRETATION.md`
   - `reqs/SPEC.md`
   - `reqs/PLAN.md`
   - `reqs/ENHANCEMENT_PLAN.md`
   - `reqs/TASKS.md`
4. Do not create `reqs/PRD.md`. The user owns that source input.
5. Do not overwrite existing files. If a target exists, leave it unchanged and report that it was skipped.
6. Update generated status in `reqs/WORKFLOW.md` only when it is safe to do so without changing acceptance checklist items.
7. Finish by reporting created/skipped files and the next likely step.

## Completion Criteria

The workflow is initialized when all shared workflow artifacts exist: `reqs/CONSTITUTION.md`, `reqs/WORKFLOW.md`, `reqs/INTERPRETATION.md`, `reqs/SPEC.md`, `reqs/PLAN.md`, `reqs/ENHANCEMENT_PLAN.md`, and `reqs/TASKS.md`.
