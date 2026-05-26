#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_root}"

if [ ! -f .env ]; then
  cp .env.example .env
  echo "Created .env from .env.example"
fi

mkdir -p \
  .state/codex \
  .state/gh \
  .state/ssh \
  .state/commandhistory \
  workspace/repos

docker compose up -d --build workspace
docker compose exec --user codex workspace codex --version
docker compose exec --user codex workspace install-platform-skills

echo "Workspace is running. Open a shell with: bash scripts/workspace-shell.sh"
