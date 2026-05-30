# Architecture

## Current MVP

The platform is a single-user hosted development environment:

```text
Windows laptop
  -> Tailscale private network
  -> SSH to Linux cloud VM
  -> dedicated codex user on the VM host
  -> Codex CLI + VS Code Remote SSH + repo files
```

The first cloud target is OVH VPS-2 on Ubuntu 24.04 LTS. The cloud VM is the
operator boundary. Tailscale provides private access to the VM. Codex runs
directly as the dedicated host workspace user, so agent commands operate on the
cloud-hosted files without a persistent devcontainer hop.

Docker is not the MVP workspace boundary. It can still be introduced later for
application services, preview stacks, databases, or explicitly isolated task
runners.

## Repository Layout

- `scripts/`: host bootstrap, workspace setup, shell access, backup, restore, and verification.
- `docs/`: architecture, deployment, development, and security notes.
- `docs/providers/`: provider-specific runbooks for the current hosting target.
- `skills/`: requirements workflow skills installed into the hosted Codex environment.
- `reqs/PRD.md`: source product direction for the platform.

## Persistence

Runtime state is kept under a single managed host workspace root, `~/workspace`
by default:

- `~/workspace/repos`: additional working repositories.
- `~/workspace/state/codex`: Codex config, auth, history, logs, and installed skills.
- `~/workspace/state/gh`: GitHub CLI state.
- `~/workspace/state/glab`: GitLab CLI state.
- `~/workspace/state/ssh`: SSH keys/config for the workspace user, including
  the optional GitHub/GitLab workspace key.
- `~/workspace/state/commandhistory`: shell history.
- `~/workspace/backups`: local backup archives and restore metadata.

`scripts/start-workspace.sh` links the workspace user's home paths to those
directories, including `~/.codex`, `~/.config/gh`, `~/.config/glab-cli`, and
`~/.ssh`.

## Access

Routine access is through SSH to the VM over Tailscale:

- use VS Code Remote SSH to open the repo as the `codex` user, or
- SSH into the VM and run `bash scripts/workspace-shell.sh`.

Do not expose raw development, admin, SSH, or workspace services publicly by
default. Public SSH is only a bootstrap path until Tailscale SSH is confirmed.

## Codex Runtime

The host bootstrap installs `@openai/codex` through npm with a pinned version
from `.env`. The workspace setup script installs this repo's
`requirements-workflow-*` skill directories into `$CODEX_HOME/skills`.

The generated Codex config uses `workspace-write` sandboxing, stores history,
and trusts the platform repo plus `~/workspace/repos`.

## Git Hosting Auth

GitHub and GitLab auth are handled by the official CLIs plus SSH. Token files
or token environment variables are used once by `scripts/setup-git-auth.sh`; the
resulting CLI state lives under `~/workspace/state/gh` and
`~/workspace/state/glab`. The same script can create one workspace SSH key under
`~/workspace/state/ssh`, upload the public key to both accounts, and configure
Git to use the CLI credential helpers for HTTPS operations.
