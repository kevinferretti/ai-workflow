# Hosted AI Development Workflow Platform PRD

## Purpose

Build a fully deployable, personal AI development workflow platform that can be hosted in the cloud and accessed from anywhere. The platform should let the owner develop inside a persistent cloud workspace using AI agents, version-controlled workflow artifacts, and familiar development tools.

This repo is intended to evolve into the platform repo: it should track the deployable environment, the opinionated workflow, and the history of changes to that workflow over time.

## Background

The current repo defines reusable requirements workflow skills and shared markdown templates. The desired next step is to make the repo define a deployable runtime environment, not only reusable workflow instructions.

The owner currently develops locally on Windows using Codex and VS Code. The hosted platform should preserve as much of that working style as practical while moving the actual development environment into a cloud-hosted workspace.

## Product Goals

- Provide a single persistent hosted development workspace that can be accessed from the owner's laptop and, eventually, phone.
- Support normal interactive AI development with single prompts and responses, similar to the owner's current local Codex usage.
- Allow the owner to use VS Code against the hosted workspace.
- Run Codex CLI inside the hosted workspace so agent actions operate directly on cloud-hosted repo files.
- Keep the platform self-hosted on a cloud VM with repo-defined provisioning scripts.
- Make the workflow opinionated but easy to evolve over time.
- Track platform and workflow evolution in this repo.
- Prefer real production wiring over deterministic demo behavior that masks failures.

## Target User

The initial product is single-user only.

The owner should be able to:

- Connect from a Windows laptop.
- Open and edit repositories in VS Code.
- Run Codex CLI in the hosted workspace.
- Send prompts and receive responses in a familiar development loop.
- Persist code, workflow state, and agent outputs across restarts.
- Deploy and update the environment from version-controlled definitions.

## MVP Scope

### Hosting Model

- The platform runs on a Linux cloud VM.
- The first provider target is OVH VPS-2 running Ubuntu 24.04 LTS.
- The runtime is a dedicated non-root workspace user on the VM host.
- The workspace is a single persistent environment, not per-task or ephemeral.
- Workspace data persists across VM reboots.
- Infrastructure should be understandable and maintainable by one person.

### Access Model

- Laptop access uses VS Code Remote SSH or Codex App SSH into the cloud workspace user.
- Codex CLI runs inside the hosted workspace.
- The local Codex desktop app can connect over SSH when that path is available.
- The Codex app-server / remote-control path may be investigated as an experiment, but the MVP must not depend on a separate app server.
- Phone access is not required to provide full development capability in the MVP.

### Security Model

- The MVP is private and single-user.
- Tailscale is the initial private access layer.
- No raw development, admin, SSH, or workspace service should be exposed publicly by default.
- Cloudflare Access is deferred for future browser/PWA surfaces.
- The workspace should run as a dedicated non-root user.
- Secrets must be injected at runtime and must not be committed to the repo.
- Git should remain the primary record of meaningful source changes.
- Destructive actions and deployment actions should require explicit owner approval.

### Development Tooling

- The workspace should include the baseline tools needed for this repo and similar development work.
- The workspace should support installing and running Codex CLI.
- The repo's requirements workflow skills should be available inside the hosted Codex environment.
- VS Code should be able to open the hosted workspace.
- The owner should be able to run shells, tests, git commands, and Codex prompts inside the environment.

### Workflow Artifacts

- The repo should keep using the `reqs/` workflow.
- Requirements should flow through:

```text
PRD.md -> INTERPRETATION.md -> SPEC.md -> PLAN.md -> TASKS.md
```

- Future ideas should be captured without prematurely mixing them into MVP implementation tasks.

## Non-Goals For MVP

- No multi-user support.
- No team RBAC.
- No Kubernetes requirement.
- No public unauthenticated services.
- No email notifications.
- No full phone-native development interface.
- No requirement to use a Windows VM solely because the owner's laptop runs Windows.
- No requirement for a separate Codex app-server or remote-control service in the first version.
- No fake demo agent behavior that hides missing production integrations.

## Future Expansion

Potential future capabilities include:

- Cloudflare Access in front of selected browser apps.
- A PWA for prompt submission, run status, approvals, logs, and notifications.
- Push notifications to phone and laptop.
- Lightweight notification adapters such as ntfy, Pushover, Slack, or Discord.
- Browser-based VS Code through code-server or OpenVSCode Server.
- Codex app-server / remote-control integration if it proves stable enough.
- Per-repo workspaces.
- Ephemeral task workspaces for safer agent execution.
- Agent run queue and background jobs.
- Command transcripts, audit logs, and cost tracking.
- Deployment approval workflows.
- Network egress controls for agent runs.
- Short-lived cloud credentials.
- Backups and restore testing.

## Success Criteria

The MVP is successful when:

- A fresh cloud VM can be prepared from the repo's documented setup.
- The host workspace can be prepared reliably on the VM with repo-defined scripts.
- Runtime state can be backed up and restored using repo-defined scripts.
- The owner can connect over Tailscale.
- The owner can open the workspace from VS Code on a Windows laptop.
- The owner can run Codex CLI inside the hosted workspace.
- Codex can read and modify files in the hosted repo.
- Changes persist across VM reboot.
- Workflow skills are available to Codex inside the hosted environment.
- No unintended public services are exposed.
- The repo contains enough documentation to rebuild the environment from scratch.

## Open Questions

- Should the repo include a provisioning tool such as Terraform or OpenTofu, or are host scripts sufficient for the MVP?
- Which base development tools should be installed by the first host bootstrap?
- Which secret store should be used for the first version?
- What backup target and retention policy should be used for the persistent workspace volume?
- What minimum audit trail is required for the first version?
- Which operations should require explicit approval in the first implementation?
