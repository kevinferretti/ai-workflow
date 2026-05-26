# Backup And Restore

Backups cover the runtime state that is intentionally not committed to git:

- `.env`
- `.state/codex`
- `.state/gh`
- `.state/ssh`
- `.state/commandhistory`
- `workspace/repos`

Treat every backup archive as sensitive. It can contain Codex auth, GitHub auth,
SSH keys, shell history, private repository contents, and prompts.

## Create A Consistent Backup

From the platform repo on the VM:

```bash
docker compose stop workspace
bash scripts/backup-workspace.sh
docker compose up -d workspace
bash scripts/check-workspace.sh
```

The archive is written to `backups/workspace-<timestamp>.tar.gz` by default.

For an explicit live backup while the workspace is running:

```bash
bash scripts/backup-workspace.sh --live
```

Use `--live` only when you accept that a repo, Codex state file, or shell
history file could change while the archive is being created.

## Restore On The Same VM

Stop the workspace first:

```bash
docker compose stop workspace
bash scripts/restore-workspace.sh backups/workspace-<timestamp>.tar.gz
bash scripts/start-workspace.sh
bash scripts/check-workspace.sh
```

If runtime state already exists, restore refuses to continue. To preserve the
existing state under `backups/pre-restore-*` and then restore:

```bash
bash scripts/restore-workspace.sh --force backups/workspace-<timestamp>.tar.gz
```

Preview an archive without changing files:

```bash
bash scripts/restore-workspace.sh --dry-run backups/workspace-<timestamp>.tar.gz
```

## Restore On A Fresh OVH VPS

1. Provision the OVH VPS and clone this repo using `docs/providers/ovh.md`.
2. Copy the backup archive onto the VPS.
3. From the platform repo, run:

```bash
bash scripts/restore-workspace.sh /path/to/workspace-<timestamp>.tar.gz
bash scripts/start-workspace.sh
bash scripts/check-workspace.sh
```

Then connect with VS Code Remote SSH over Tailscale and continue from the
restored workspace.

## What This Does Not Replace

OVH provider backups are still useful for whole-VM recovery. These repo-defined
backups are the portable restore path for the platform's actual workspace state.

The first implementation writes local archives only. Remote encrypted backup
targets are a future hardening step.
