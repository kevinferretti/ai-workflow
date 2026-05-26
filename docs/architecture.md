# Architecture

## Current MVP

The platform is a single-user hosted development environment:

```text
Windows laptop
  -> Tailscale private network
  -> SSH to Linux cloud VM
  -> Docker Compose workspace
  -> Codex CLI + VS Code Dev Containers + repo files
```

The first cloud target is OVH VPS-2 on Ubuntu 24.04 LTS. The cloud VM is
the operator boundary. Tailscale provides private access to the VM. Docker
provides the persistent workspace runtime. Codex runs inside the workspace
container, so agent commands operate on the cloud-hosted files.

## Repository Layout

- `docker-compose.yml`: starts the persistent workspace.
- `infra/workspace/`: workspace image, entrypoint, Codex defaults, and shell setup.
- `.devcontainer/devcontainer.json`: VS Code Dev Containers metadata.
- `scripts/`: host bootstrap, workspace startup, shell access, and verification.
- `docs/`: architecture, deployment, development, and security notes.
- `docs/providers/`: provider-specific runbooks for the current hosting target.
- `skills/`: requirements workflow skills installed into the hosted Codex environment.
- `reqs/PRD.md`: source product direction for the platform.

## Persistence

Runtime state is mounted from gitignored host directories:

- `.state/codex`: Codex config, auth, history, logs, and installed skills.
- `.state/gh`: GitHub CLI state.
- `.state/ssh`: SSH keys/config for the workspace user.
- `.state/commandhistory`: shell history.
- `workspace/repos`: additional working repositories.

The platform repo itself is mounted at `/workspace/platform`.

## Access

The Compose file does not publish any container ports. For the MVP, access is through SSH to the VM over Tailscale, then either:

- run `docker compose exec workspace zsh -l`, or
- use VS Code Remote SSH to the VM and reopen/attach to the Compose workspace container.

## Codex Runtime

The workspace image installs `@openai/codex` through npm with a pinned version from `.env`. The entrypoint installs this repo's `requirements-workflow-*` skill directories into `$CODEX_HOME/skills` on container start.

The default Codex config uses `workspace-write` sandboxing, stores history, and trusts `/workspace/platform` plus `/workspace/repos`.
