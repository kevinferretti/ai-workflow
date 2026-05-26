# Development Workflow

## Laptop Workflow

1. Connect the laptop to Tailscale.
2. Use VS Code Remote SSH to connect to the cloud VM.
3. Open this platform repo on the VM.
4. Start the workspace:

```bash
bash scripts/start-workspace.sh
```

5. In VS Code, use Dev Containers to attach to the running `ai-workspace` container or reopen the folder in the container.
6. Run Codex inside the container:

```bash
codex
```

The platform repo is available at `/workspace/platform`. Additional repos belong under `/workspace/repos`.

## Terminal Workflow

From the VM:

```bash
bash scripts/workspace-shell.sh
```

From inside that shell:

```bash
codex
```

## Updating Workflow Skills

The container entrypoint installs the repo's `skills/requirements-workflow-*` directories into `$CODEX_HOME/skills` on start. To refresh manually:

```bash
install-platform-skills
```

Start a new Codex thread after changing skills so discovery can refresh.

## Adding Repositories

Clone additional repos inside the workspace:

```bash
cd /workspace/repos
git clone <repo-url>
```

Those repos persist in the gitignored `workspace/repos` host directory.

## GitLab Workflow

The workspace image includes `glab` for GitLab merge requests, pipelines,
issues, and repository metadata. Git cloning can still use plain SSH:

```bash
cd /workspace/repos
git clone git@labs.gauntletai.com:<namespace>/<project>.git
```

For GitLab API operations, authenticate inside the workspace:

```bash
glab auth login --hostname labs.gauntletai.com
```

`glab` state persists in the gitignored `.state/glab` host directory.
