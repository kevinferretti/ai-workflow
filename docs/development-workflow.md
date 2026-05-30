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

## GitHub And GitLab Auth

`scripts/start-workspace.sh` runs `scripts/setup-git-auth.sh --non-interactive`
by default. If `.env` points to token files, the setup authenticates `gh` and
`glab`, creates a workspace SSH key if needed, uploads that key to both
accounts, and configures Git helpers.

For a fresh login:

```bash
install -m 0600 /dev/null ~/github-token
install -m 0600 /dev/null ~/gitlab-token
nano ~/github-token
nano ~/gitlab-token
nano .env
bash scripts/setup-git-auth.sh --require-auth
```

Set `GITHUB_TOKEN_FILE=~/github-token` and
`GITLAB_TOKEN_FILE=~/gitlab-token` in `.env`. Tokens can be removed after
`gh auth status` and `glab auth status` pass, because the CLI auth state is
persisted under `~/workspace/state`.

For a classic GitHub token, use `repo`, `read:org`, `gist`, and
`admin:public_key` when `WORKSPACE_GIT_UPLOAD_SSH_KEY=1`. For GitLab, use an
`api` token so `glab` can add the SSH key.

## GitLab Workflow

The host bootstrap installs `glab` for GitLab merge requests, pipelines, issues,
and repository metadata. Git cloning can still use plain SSH:

```bash
cd ~/workspace/repos
git clone git@labs.gauntletai.com:<namespace>/<project>.git
```

For GitLab API operations, authenticate as the workspace user:

```bash
bash scripts/setup-git-auth.sh --require-auth
```

`glab` state persists in `~/workspace/state/glab` by default.
