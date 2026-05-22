# Requirements Workflow Conventions

Use these conventions for every requirements workflow skill.

## Artifacts

All project-local workflow files live in `reqs/`:

- `PRD.md`: raw product/stakeholder input; created by the user, not by init.
- `CONSTITUTION.md`: workflow governance for requirements, spec, planning, and tasking.
- `WORKFLOW.md`: generated status plus human acceptance checklist.
- `INTERPRETATION.md`: current understanding of requirements and open questions.
- `SPEC.md`: committed product/build contract.
- `PLAN.md`: core implementation plan only.
- `ENHANCEMENT_PLAN.md`: future expansion plan only.
- `TASKS.md`: active core implementation tasks only.

## Source Of Truth

`CONSTITUTION.md` governs the requirements pipeline. `AGENTS.md` governs agent behavior in the repo.

The artifact flow is:

```text
PRD.md -> INTERPRETATION.md -> SPEC.md -> PLAN.md -> TASKS.md
INTERPRETATION.md + SPEC.md deferred scope -> ENHANCEMENT_PLAN.md
```

Downstream work may reveal missing requirement detail, but requirement changes should flow back through `INTERPRETATION.md` before changing downstream artifacts.

## Invocation Boundaries

Skills must be manually invoked. Do not automatically invoke the next workflow skill. At the end of a step, report the next appropriate skill for the user to run.

## Status And Acceptance

Skills may update `WORKFLOW.md` generated status.

Skills must not check or uncheck acceptance checklist items unless the user explicitly asks. Acceptance means reviewed and approved, not merely generated or present.

## Open Questions

Use one `Open Questions` section in `INTERPRETATION.md`. Use lightweight stable IDs such as `Q-001` when helpful. Preserve IDs when obvious, but do not treat ID stability as a hard requirement.

Use neutral language for unclear, incompatible, missing, or mismatched requirements. Surface the issue as a question to answer instead of adding a separate issue category.

## Change Notes

When an LLM-driven update changes requirement understanding, append a short dated entry to `INTERPRETATION.md` under `Change Notes`.

Include source context when provided, such as "Stakeholder note from Jane" or "Updated PRD section on reporting." Do not log purely mechanical formatting edits.

## Editing Rules

Read existing files before editing. Preserve user-authored content when it remains compatible with the current understanding. If a safe merge is not possible, stop and explain exactly what needs user input.

Use repository-relative paths in generated markdown. Do not include machine-specific absolute paths inside workflow artifacts.

## Downstream Gates

`SPEC.md` should not invent product scope. It may structure, clarify, and make implementation-neutral detail explicit, but new product scope should first update `INTERPRETATION.md`.

By default, plan generation requires `SPEC accepted for planning` to be checked in `WORKFLOW.md`. Task generation requires `PLAN accepted for tasking` to be checked. The user may explicitly request a draft despite an unchecked gate.

`TASKS.md` is for active core implementation only. Keep enhancement work out of `TASKS.md` unless the user explicitly activates that work and regenerates tasks for that scope.
