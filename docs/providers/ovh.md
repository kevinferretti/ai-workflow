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

The VPS line is a budget shared-hosting product. That is acceptable for the MVP because the platform is single-user, persistent, and mostly interactive. If builds or agent runs feel noisy, the next step is to move the same repo/runtime to a stronger VM provider without changing the workspace model.

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
git clone <PLATFORM_REPO_URL> ~/requirements-workflow-skills
cd ~/requirements-workflow-skills
bash scripts/bootstrap-ubuntu-host.sh
```

Log out and reconnect so Docker group membership applies:

```powershell
ssh ubuntu@<OVH_IPV4>
```

Join the tailnet:

```bash
cd ~/requirements-workflow-skills
sudo tailscale up --ssh
bash scripts/check-host.sh
```

Do not remove public SSH access until this succeeds from a second terminal:

```powershell
ssh ubuntu@<TAILSCALE_IP>
```

## Start The Workspace

On the VPS:

```bash
cd ~/requirements-workflow-skills
cp .env.example .env
bash scripts/start-workspace.sh
bash scripts/check-workspace.sh
```

Before logging in to Codex or GitHub, run a backup/restore test from
`docs/backup-restore.md`. After credentials are added, every backup archive must
be treated as sensitive.

Open the workspace shell:

```bash
bash scripts/workspace-shell.sh
codex login
codex
```

## VS Code Access

Use VS Code Remote SSH from the laptop to connect to the VPS over Tailscale:

```text
ubuntu@<TAILSCALE_IP>
```

Then either open the repo on the host or attach VS Code to the running `ai-workspace` container. The workspace path inside the container is:

```text
/workspace/platform
```

Additional repos should live under:

```text
/workspace/repos
```

## Security Baseline

- Treat public SSH as bootstrap access.
- Prefer Tailscale SSH for routine access.
- Keep `docker-compose.yml` free of published ports unless a future feature explicitly needs one.
- Keep Codex, GitHub, SSH, and shell state under `.state/`.
- Treat `.state/` backups as sensitive because they can contain auth material.
- Keep provider backups enabled, but do not treat them as the only restore plan.

## Provider References

- OVH VPS getting started: <https://docs.ovhcloud.com/en/guides/bare-metal-cloud/virtual-private-servers/starting-with-a-vps>
- OVH SSH keys: <https://docs.ovhcloud.com/en/guides/bare-metal-cloud/dedicated-servers/creating-ssh-keys>
- OVH VPS pricing: <https://www.ovhcloud.com/en/vps/>
