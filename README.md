# Hosted AI Development Workflow Platform

This repo is evolving into a deployable, opinionated, personal AI development workflow platform.

The current MVP target is:

- OVH VPS-2 as the first cloud target
- Linux cloud VM
- Docker Compose
- single persistent workspace container
- Tailscale-private access
- VS Code Remote SSH from a laptop
- Codex CLI running inside the hosted workspace
- GitHub CLI and GitLab CLI available inside the hosted workspace
- this repo's workflow skills installed into the hosted Codex environment

No workspace ports are published by default.

## Quick Start On A Cloud VM

On a fresh Ubuntu VM:

```bash
bash scripts/bootstrap-ubuntu-host.sh
```

After logging out and back in:

```bash
sudo tailscale up --ssh
bash scripts/check-host.sh
cp .env.example .env
bash scripts/start-workspace.sh
bash scripts/check-workspace.sh
```

Open a shell in the hosted workspace:

```bash
bash scripts/workspace-shell.sh
codex
```

See:

- `docs/architecture.md`
- `docs/deploy-cloud-vm.md`
- `docs/providers/ovh.md`
- `docs/development-workflow.md`
- `docs/security.md`
- `docs/backup-restore.md`

## Runtime Layout

- `docker-compose.yml`: persistent workspace runtime.
- `infra/workspace/`: Docker image, entrypoint, shell setup, and Codex defaults.
- `.devcontainer/devcontainer.json`: VS Code Dev Containers metadata.
- `scripts/`: bootstrap, start, shell, and verification scripts.
- `skills/`: reusable requirements workflow skills.
- `reqs/PRD.md`: product direction for the platform MVP.

Gitignored runtime state:

- `.state/`
- `workspace/`
- `backups/`
- `.env`

## Requirements Workflow Skills

The repo also tracks reusable Codex requirements workflow skills implemented as separate manually invoked skills.

## Skills

- `$requirements-workflow-init`
- `$requirements-workflow-digest`
- `$requirements-workflow-resolve`
- `$requirements-workflow-update`
- `$requirements-workflow-status`
- `$requirements-workflow-spec`
- `$requirements-workflow-plan`
- `$requirements-workflow-enhancement-plan`
- `$requirements-workflow-tasks`

Shared conventions and templates live in `skills/requirements-workflow-shared/`.

## Install Or Update Locally

From this repo root:

```powershell
$dest = Join-Path $HOME ".codex\skills"
New-Item -ItemType Directory -Force -Path $dest | Out-Null
Copy-Item -Recurse -Force -Path ".\skills\requirements-workflow-*" -Destination $dest
```

Start a new Codex thread after installing or updating skills so discovery can refresh.

## Push To GitHub

Create an empty GitHub repo, then run:

```powershell
git remote add origin <github-repo-url>
git branch -M main
git push -u origin main
```
