# Hosted AI Development Workflow Platform

This repo is evolving into a deployable, opinionated, personal AI development workflow platform.

The current MVP target is:

- OVH VPS-2 as the first cloud target
- Linux cloud VM
- dedicated `codex` workspace user on the VM host
- Tailscale-private access
- VS Code Remote SSH from a laptop
- Codex CLI running inside the hosted workspace
- GitHub CLI and GitLab CLI authenticated inside the hosted workspace when token inputs are provided
- a workspace SSH key that can be uploaded to GitHub and GitLab for clone/push access
- this repo's workflow skills installed into the hosted Codex environment

No raw development or admin services should be exposed publicly by default.

## Quick Start On A Cloud VM

On a fresh Ubuntu VM:

```bash
sudo apt-get update
sudo apt-get install -y git
git clone <PLATFORM_REPO_URL> ~/ai-workflow
cd ~/ai-workflow
bash scripts/bootstrap-ubuntu-host.sh
```

Then join the tailnet, connect as the workspace user, and prepare the host workspace runtime state:

```bash
sudo tailscale up --ssh
ssh codex@<TAILSCALE_IP>
cd ~/ai-workflow
cp .env.example .env
bash scripts/start-workspace.sh
bash scripts/check-host.sh
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
- `docs/android-ssh.md`
- `docs/security.md`
- `docs/backup-restore.md`

## Runtime Layout

- `scripts/`: host bootstrap, workspace setup, shell, backup, restore, and verification scripts.
- `skills/`: reusable requirements workflow skills.
- `reqs/PRD.md`: product direction for the platform MVP.

Default host layout:

- `~/ai-workflow`: this platform repo.
- `~/workspace/repos`: additional working repositories.
- `~/workspace/state`: Codex, GitHub CLI, GitLab CLI, SSH, and shell state.
- `~/workspace/backups`: local backup archives and restore metadata.

Gitignored platform-local files:

- `.env`
- `.state/`, `workspace/`, and `backups/` for legacy or explicit local overrides.

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
