# Development Workflow

## Laptop Workflow

1. Connect the laptop to Tailscale.
2. Use VS Code Remote SSH to connect to the cloud VM as the workspace user.
3. Open this platform repo on the VM.
4. Prepare or refresh the workspace state:

```bash
bash scripts/start-workspace.sh
bash scripts/check-workspace.sh
```

5. Run Codex from the platform repo or from `~/workspace/repos`:

```bash
codex
```

The platform repo usually lives at `~/ai-workflow`. Additional repos belong
under `~/workspace/repos`.

## Terminal Workflow

From the VM as the workspace user:

```bash
bash scripts/workspace-shell.sh
codex
```

## Android SSH Workflow

For phone access, use Android Tailscale plus Termux/OpenSSH to connect to the VM
over the tailnet, then run the normal terminal workflow. See
`docs/android-ssh.md`.

## Updating Workflow Skills

`scripts/start-workspace.sh` installs the repo's `skills/requirements-workflow-*`
directories into `$CODEX_HOME/skills`. To refresh manually:

```bash
bash scripts/install-platform-skills.sh
```

Start a new Codex thread after changing skills so discovery can refresh.

## Adding Repositories

Clone additional repos inside the workspace repo directory:

```bash
cd ~/workspace/repos
git clone <repo-url>
```

Those repos persist under the managed workspace root and are included in
repo-defined backups.

## GitLab Workflow

The host bootstrap installs `glab` for GitLab merge requests, pipelines, issues,
and repository metadata. Git cloning can still use plain SSH:

```bash
cd ~/workspace/repos
git clone git@labs.gauntletai.com:<namespace>/<project>.git
```

For GitLab API operations, authenticate as the workspace user:

```bash
glab auth login --hostname labs.gauntletai.com
```

`glab` state persists in `~/workspace/state/glab` by default.
