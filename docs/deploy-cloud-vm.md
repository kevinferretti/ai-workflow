# Deploy To A Cloud VM

The first opinionated target is OVH VPS-2 running Ubuntu 24.04 LTS. Use
`docs/providers/ovh.md` for the provider-specific path.

## VM Requirements

- Ubuntu 24.04 LTS is the initial target.
- At least 2 vCPU and 4 GB RAM for light work; use more for large builds.
- Disk size should account for package caches, repos, `.state/`, and backups.
- Inbound public access should be restricted. Prefer Tailscale SSH over public SSH.

## Bootstrap The VM

On a fresh Ubuntu VM, clone this repo as the initial cloud user and run:

```bash
bash scripts/bootstrap-ubuntu-host.sh
```

The bootstrap installs baseline development tools, Node.js, Codex CLI, GitHub
CLI, GitLab CLI, Tailscale, and SSH. It also creates the dedicated workspace
user from `WORKSPACE_USER`, defaulting to `codex`, and seeds the current repo
checkout into that user's home without `.env`, `.state`, `workspace`, or
`backups`.

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

The resulting Codex state is stored under `.state/codex`, which is gitignored
and should be backed up as sensitive runtime state.

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
