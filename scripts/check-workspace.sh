#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_root}"

docker compose config >/dev/null

if docker compose config | grep -E '^[[:space:]]+ports:' >/dev/null; then
  echo "ERROR: docker-compose.yml exposes ports. The MVP should expose no workspace ports by default." >&2
  exit 1
fi

docker compose ps workspace

docker compose exec --user codex workspace bash -lc '
  set -euo pipefail
  test "$(whoami)" = "codex"
  codex --version
  node --version
  npm --version
  git --version
  python3 --version
  test -d "$CODEX_HOME/skills/requirements-workflow-init"
  test -d "$CODEX_HOME/skills/requirements-workflow-shared"
  test -w /workspace/repos
  test -f /workspace/platform/docker-compose.yml
'

echo "Workspace check passed."
