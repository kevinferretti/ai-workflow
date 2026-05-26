# Deploy To A Cloud VM

The first opinionated target is OVH VPS-2 running Ubuntu 24.04 LTS. Use
`docs/providers/ovh.md` for the provider-specific path.

## VM Requirements

- Ubuntu 24.04 LTS is the initial target.
- At least 2 vCPU and 4 GB RAM for light work; use more for large builds.
- Disk size should account for Docker images, package caches, repos, and `.state/`.
- Inbound public access should be restricted. Prefer Tailscale SSH over public SSH.

## Bootstrap The VM

On a fresh Ubuntu VM, run:

```bash
bash scripts/bootstrap-ubuntu-host.sh
```

Then log out and back in so Docker group membership applies.

Join the tailnet:

```bash
sudo tailscale up --ssh
bash scripts/check-host.sh
```

After Tailscale is active, restrict the cloud firewall so routine access uses the tailnet. Do not publish workspace application ports for the MVP.

## Start The Workspace

Clone this repo on the VM, then run:

```bash
cp .env.example .env
bash scripts/start-workspace.sh
```

Open a shell in the workspace:

```bash
bash scripts/workspace-shell.sh
```

Verify the workspace:

```bash
bash scripts/check-workspace.sh
```

## Codex Login

Run this inside the workspace shell:

```bash
codex login
```

The resulting Codex state is stored under `.state/codex`, which is gitignored and should be backed up as sensitive runtime state.

## Rebuild

After changing the workspace image or Compose file:

```bash
docker compose up -d --build workspace
bash scripts/check-workspace.sh
```

## Backup Before Real Use

Before putting long-lived Codex, GitHub, or SSH auth into the workspace, read
`docs/backup-restore.md` and create a first backup/restore test.
