# Requirements Workflow Constitution

## Purpose

This file governs the requirements, specification, planning, and task workflow for this repo.

`AGENTS.md` governs general agent and engineering behavior. This constitution governs the `reqs/` artifact pipeline.

## Source Of Truth

- `PRD.md` is raw source input from product, stakeholders, or discovery.
- `INTERPRETATION.md` is the current understanding of requirements and open questions.
- `SPEC.md` is the product/build contract derived from `INTERPRETATION.md`.
- `PLAN.md` is the core implementation strategy derived from `SPEC.md`.
- `ENHANCEMENT_PLAN.md` is future expansion strategy derived from expansion areas and deferred scope.
- `TASKS.md` is the active core implementation task list derived from `PLAN.md`.

## Change Flow

Downstream artifacts may reveal missing requirement detail. Requirement changes should update `INTERPRETATION.md` before changing `SPEC.md`, `PLAN.md`, or `TASKS.md`.

## Scope Rules

`SPEC.md` may organize and clarify requirements, but it should not invent product scope.

`PLAN.md` and `TASKS.md` should stay focused on core/base requirements.

Enhancement work belongs in `ENHANCEMENT_PLAN.md` until explicitly activated.

## Workflow Status

Skills may update generated status in `WORKFLOW.md`.

Only a human should check or uncheck acceptance checklist items unless they explicitly ask an agent to do so.

Acceptance means the artifact has been reviewed and approved for the next workflow step.
