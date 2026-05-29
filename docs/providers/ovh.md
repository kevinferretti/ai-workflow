# OVH Deployment Target

OVH VPS is the first opinionated hosting target for this platform.

## Chosen Plan

Start with **OVH VPS-2**:

- Ubuntu 24.04 LTS
- 6 vCores
- 12 GB RAM
- 100 GB NVMe
- included daily provider backup
- public IPv4 for bootstrap only
- Tailscale for routine access

The VPS line is a budget shared-hosting product. That is acceptable for the MVP
because the platform is single-user, persistent, and mostly interactive. If
builds or agent runs feel noisy, the next step is to move the same repo/runtime
to a stronger VM provider without changing the host-workspace model.

## First Provision

1. Create or import an SSH key in the OVH control panel.
2. Order an OVH VPS-2.
3. Select Ubuntu 24.04 LTS.
4. Preinstall the SSH key.
5. Wait for OVH to show the VPS IPv4 address.

For Ubuntu images, OVH documents the initial username as `ubuntu`.

## Bootstrap From Windows

From PowerShell on the laptop:

```powershell
ssh ubuntu@<OVH_IPV4>
```

On the VPS:

```bash
sudo apt-get update
sudo apt-get install -y git
git clone <PLATFORM_REPO_URL> ~/ai-workflow
cd ~/ai-workflow
bash scripts/bootstrap-ubuntu-host.sh
```

Join the tailnet:

```bash
sudo tailscale up --ssh
```

Do not remove public SSH access until this succeeds from a second terminal:

```powershell
ssh codex@<TAILSCALE_IP>
```

## Prepare The Workspace

On the VPS over Tailscale as the workspace user, use the seeded repo copy:

```bash
cd ~/ai-workflow
cp .env.example .env
bash scripts/start-workspace.sh
bash scripts/check-host.sh
bash scripts/check-workspace.sh
```

Before logging in to Codex, GitHub, or GitLab, run a backup/restore test from
`docs/backup-restore.md`. After credentials are added, every backup archive must
be treated as sensitive.

Open the workspace shell:

```bash
bash scripts/workspace-shell.sh
codex login
codex
```

## VS Code And Codex App Access

Use VS Code Remote SSH or Codex App SSH from the laptop to connect to the VPS
over Tailscale:

```text
codex@<TAILSCALE_IP>
```

Open the platform repo at:

```text
~/ai-workflow
```

Additional repos should live under:

```text
~/ai-workflow/workspace/repos
```

## Security Baseline

- Treat public SSH as bootstrap access.
- Prefer Tailscale SSH for routine access.
- Do not expose raw development, admin, SSH, or workspace services publicly by default.
- Keep Codex, GitHub, GitLab, SSH, and shell state under `.state/`.
- Treat `.state/` backups as sensitive because they can contain auth material.
- Keep provider backups enabled, but do not treat them as the only restore plan.

## Provider References

- OVH VPS getting started: <https://docs.ovhcloud.com/en/guides/bare-metal-cloud/virtual-private-servers/starting-with-a-vps>
- OVH SSH keys: <https://docs.ovhcloud.com/en/guides/bare-metal-cloud/dedicated-servers/creating-ssh-keys>
- OVH VPS pricing: <https://www.ovhcloud.com/en/vps/>
