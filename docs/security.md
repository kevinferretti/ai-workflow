# Security Notes

## MVP Security Boundary

The first security boundary is private network access to a single-user cloud VM.
Tailscale protects routine operator access. The dedicated `codex` user is the
workspace boundary for the MVP; it is not a sandbox boundary against malicious
code.

Direct host execution is intentionally simpler than a persistent devcontainer,
but it has a larger blast radius. Do not run untrusted repositories with broad
credentials available to the workspace user. Anything available to that user,
including Codex auth, SSH keys, GitHub auth, and GitLab auth, is in scope for
commands run there.

## Host Account

`scripts/bootstrap-ubuntu-host.sh` creates the workspace user and grants
passwordless sudo by default. That matches the single-user development-box
model, but it means a compromised workspace user can administer the VM.

Keep public SSH as bootstrap-only access. After Tailscale SSH works, restrict
the cloud firewall so routine SSH uses the tailnet.

## Secrets

- Do not commit `.env`.
- Do not commit workspace runtime state.
- Do not commit SSH keys, Codex auth, GitHub auth, GitLab auth, cloud credentials, or API keys.
- Prefer short-lived credentials where possible.
- Treat `~/workspace/state/codex`, `~/workspace/state/gh`, `~/workspace/state/glab`, and `~/workspace/state/ssh` as sensitive backup material.
- Treat `~/workspace/backups/*.tar.gz` as sensitive because they can contain the same auth material and private repository contents.

## Public Exposure

Do not publish raw development, admin, SSH, or workspace services publicly by
default. If a browser surface is added later, put it behind Cloudflare Access or
an equivalent identity-aware proxy and keep raw admin surfaces private.

## Backups

Use `scripts/backup-workspace.sh` for portable backups of runtime state. For a
consistent archive, close active Codex sessions first. Use `--live` only when an
inconsistent snapshot is acceptable.

Provider backups are useful for whole-VM rollback, but the repo-defined backup
is the restore path when moving to a fresh VM.

## Future Hardening

- Remote encrypted backup targets with restore tests.
- Cloud firewall policy documented as code.
- Cloudflare Access for selected browser apps.
- Egress controls for agent runs.
- Optional isolated Docker task runners for risky repositories.
- Per-repo or per-task workspaces.
- Audit logs for prompts, commands, file changes, and deployments.
- Explicit deploy approvals.
