# Agent Instructions

## Engineering Style

- Prefer modular design with small, cohesive units and clear ownership boundaries.
- Match existing project patterns before creating new ones.
- Work in intelligent increments and verify each meaningful change.
- Do not add deterministic demo behavior that hides missing production wiring.
- If the application cannot do what the production workflow requires, make that failure visible.
- Keep generated requirements workflow artifacts separate from implementation unless explicitly requested.

## Platform Direction

- This repo defines a personal, single-user, cloud-hosted AI development workflow platform.
- The MVP target is a Linux cloud VM, Docker Compose, Tailscale-private access, VS Code Remote SSH, and Codex CLI running inside a persistent workspace container.
- Do not expose raw development, admin, SSH, or workspace services publicly by default.
- Secrets belong in runtime state or provider-managed stores, never in git.

## Verification

- For infrastructure changes, run `docker compose config` at minimum.
- When Docker is available, build the workspace image and run `scripts/check-workspace.sh`.
- When changing shell scripts, run `bash -n` over changed scripts.
