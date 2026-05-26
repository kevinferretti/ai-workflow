# Security Notes

## MVP Security Boundary

The first security boundary is private network access to a single-user cloud VM. Tailscale protects operator access. Docker isolates the development workspace from the VM host, but it is not a perfect security boundary.

The Compose workspace publishes no ports by default. SSH access should be to the VM over Tailscale, not to the container over the public internet.

## Codex And Containers

The workspace follows OpenAI's documented dev-container pattern: Codex runs inside a container with persistent Codex configuration and `bubblewrap` available for the inner Linux sandbox. The container grants additional capabilities so Codex sandboxing can work inside Docker.

Do not run untrusted repositories with broad credentials mounted into this workspace. Anything available in the workspace, including Codex auth, SSH keys, GitHub auth, and GitLab auth, is in scope for commands run there.

## Secrets

- Do not commit `.env`.
- Do not commit `.state/`.
- Do not commit SSH keys, Codex auth, GitHub auth, cloud credentials, or API keys.
- Prefer short-lived credentials where possible.
- Treat `.state/codex`, `.state/gh`, `.state/glab`, and `.state/ssh` as sensitive backup material.
- Treat `backups/*.tar.gz` as sensitive because they can contain the same auth material and private repository contents.

## Public Exposure

Do not add `ports:` to `docker-compose.yml` for the MVP. If a browser surface is added later, put it behind Cloudflare Access or an equivalent identity-aware proxy and keep raw admin surfaces private.

## Backups

Use `scripts/backup-workspace.sh` for portable backups of runtime state. For a
consistent archive, stop the workspace first. Use live backups only when an
inconsistent snapshot is acceptable.

Provider backups are useful for whole-VM rollback, but the repo-defined backup
is the restore path when moving to a fresh VM.

## Future Hardening

- Remote encrypted backup targets with restore tests.
- Cloud firewall policy documented as code.
- Cloudflare Access for selected browser apps.
- Egress controls for agent runs.
- Per-repo or per-task workspaces.
- Audit logs for prompts, commands, file changes, and deployments.
- Explicit deploy approvals.
