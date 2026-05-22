---
name: requirements-workflow-spec
description: Create or update reqs/SPEC.md from reqs/INTERPRETATION.md as the product/build contract. Use when explicitly invoked with $requirements-workflow-spec after interpretation is ready for spec work.
---

# Requirements Workflow Spec

Create or update `reqs/SPEC.md` from `reqs/INTERPRETATION.md`.

## Resources

Read `../requirements-workflow-shared/references/conventions.md` before acting.

Use `../requirements-workflow-shared/assets/templates/SPEC.md` when creating a new spec.

## Preconditions

Require these files:

- `reqs/CONSTITUTION.md`
- `reqs/WORKFLOW.md`
- `reqs/INTERPRETATION.md`

If any are missing, stop and report the missing files.

If `INTERPRETATION.md` has open questions and the user has not explicitly asked to proceed anyway, stop and ask whether to generate a draft spec with open questions still present.

## Workflow

1. Read the constitution, workflow status, and interpretation.
2. Create `SPEC.md` from the template if missing; otherwise read the existing spec before editing.
3. Write the build contract using these sections:
   - Problem Statement
   - Goals
   - Non-Goals
   - Core Scope
   - User Stories
   - Functional Requirements
   - Acceptance Criteria
   - Constraints
   - Edge Cases
   - Deferred / Expansion Scope
4. Do not invent product scope. If the spec needs scope not represented in `INTERPRETATION.md`, stop and tell the user to update interpretation first.
5. Update generated status in `WORKFLOW.md`. Do not alter acceptance checklist items.
6. Do not invoke another workflow skill automatically.

## Output

Report changed files, any open questions that affected the spec, and that `SPEC accepted for planning` remains a human-controlled checklist item.
