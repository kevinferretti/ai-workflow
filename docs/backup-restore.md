# Backup And Restore

Backups cover the runtime state that is intentionally not committed to git:

- `.env`
- `~/workspace/repos`
- `~/workspace/state/codex`
- `~/workspace/state/gh`
- `~/workspace/state/glab`
- `~/workspace/state/ssh`
- `~/workspace/state/commandhistory`

Treat every backup archive as sensitive. It can contain Codex auth, GitHub auth,
GitLab CLI auth, SSH keys, shell history, private repository contents, and
prompts.

## Create A Consistent Backup

From the platform repo on the VM, close active Codex sessions first, then run:

```bash
bash scripts/backup-workspace.sh
bash scripts/check-workspace.sh
```

The archive is written to `~/workspace/backups/workspace-<timestamp>.tar.gz` by
default.

For an explicit live backup while Codex may be writing state:

```bash
bash scripts/backup-workspace.sh --live
```

Use `--live` only when you accept that a repo, Codex state file, or shell
history file could change while the archive is being created.

## Restore On The Same VM

Close active Codex sessions first:

```bash
bash scripts/restore-workspace.sh ~/workspace/backups/workspace-<timestamp>.tar.gz
bash scripts/start-workspace.sh
bash scripts/check-workspace.sh
```

If runtime state already exists, restore refuses to continue. To preserve the
existing state under `~/workspace/backups/pre-restore-*` and then restore:

```bash
bash scripts/restore-workspace.sh --force ~/workspace/backups/workspace-<timestamp>.tar.gz
```

Preview an archive without changing files:

```bash
bash scripts/restore-workspace.sh --dry-run ~/workspace/backups/workspace-<timestamp>.tar.gz
```

## Restore On A Fresh OVH VPS

1. Provision the OVH VPS and clone this repo using `docs/providers/ovh.md`.
2. Copy the backup archive onto the VPS.
3. From the platform repo as the workspace user, run:

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
