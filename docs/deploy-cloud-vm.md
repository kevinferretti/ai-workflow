# Deploy To A Cloud VM

The first opinionated target is OVH VPS-2 running Ubuntu 24.04 LTS. Use
`docs/providers/ovh.md` for the provider-specific path.

## VM Requirements

- Ubuntu 24.04 LTS is the initial target.
- At least 2 vCPU and 4 GB RAM for light work; use more for large builds.
- Disk size should account for package caches, `~/workspace/repos`,
  `~/workspace/state`, and backups.
- Inbound public access should be restricted. Prefer Tailscale SSH over public SSH.

## Bootstrap The VM

On a fresh Ubuntu VM, clone this repo as the initial cloud user and run:

```bash
bash scripts/bootstrap-ubuntu-host.sh
```

The bootstrap installs baseline development tools, Node.js, Codex CLI, GitHub
CLI, GitLab CLI, Tailscale, and SSH. It also creates the dedicated workspace
user from `WORKSPACE_USER`, defaulting to `codex`, and seeds the current repo
checkout into that user's home without `.env` or legacy platform-local runtime
directories such as `.state`, `workspace`, and `backups`.

Join the tailnet:

```bash
sudo tailscale up --ssh
```

After Tailscale is active, restrict the cloud firewall so routine access uses
the tailnet. Do not publish raw workspace services for the MVP.

## Prepare The Workspace User

Connect over Tailscale as the workspace user:

```bash
ssh codex@<TAILSCALE_IP>
```

Use the seeded repo copy, then run:

```bash
cd ~/ai-workflow
cp .env.example .env
bash scripts/start-workspace.sh
bash scripts/check-host.sh
bash scripts/check-workspace.sh
```

Open a shell in the workspace:

```bash
bash scripts/workspace-shell.sh
```

## Codex Login

Run this as the workspace user:

```bash
codex login
```

The resulting Codex state is stored under `~/workspace/state/codex` by default
and should be backed up as sensitive runtime state.

## GitHub And GitLab Login

For fully automatic setup, create token files readable only by the workspace
user, point `.env` at them, then rerun the auth setup:

```bash
install -m 0600 /dev/null ~/github-token
install -m 0600 /dev/null ~/gitlab-token
nano ~/github-token
nano ~/gitlab-token
nano .env
bash scripts/setup-git-auth.sh --require-auth
```

Use `GITHUB_TOKEN_FILE=~/github-token` and
`GITLAB_TOKEN_FILE=~/gitlab-token` in `.env`. By default the script creates a
workspace SSH key, uploads it to both accounts after CLI auth, configures Git
helpers, and keeps GitHub/GitLab CLI state under `~/workspace/state`.
For a classic GitHub token, use `repo`, `read:org`, `gist`, and
`admin:public_key` when `WORKSPACE_GIT_UPLOAD_SSH_KEY=1`. For GitLab, use an
`api` token so `glab` can add the SSH key.

## Update Or Reprovision

After changing pinned tool versions, host bootstrap logic, or workspace setup:

```bash
bash scripts/bootstrap-ubuntu-host.sh
bash scripts/start-workspace.sh
bash scripts/check-host.sh
bash scripts/check-workspace.sh
```

## Backup Before Real Use

Before putting long-lived Codex, GitHub, GitLab, or SSH auth into the workspace,
read `docs/backup-restore.md` and create a first backup/restore test.
