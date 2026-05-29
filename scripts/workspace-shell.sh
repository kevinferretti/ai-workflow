#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "${repo_root}"

if [ -f .env ]; then
  set -a
  # shellcheck disable=SC1091
  . ./.env
  set +a
fi

to_abs() {
  local raw="$1"
  case "${raw}" in
    /*)
      realpath -m "${raw}"
      ;;
    *)
      realpath -m "${repo_root}/${raw#./}"
      ;;
  esac
}

export PLATFORM_ROOT="${repo_root}"
export WORKSPACE_REPOS="$(to_abs "${WORKSPACE_REPOS_DIR:-./workspace/repos}")"
export CODEX_HOME="$(to_abs "${WORKSPACE_CODEX_STATE_DIR:-./.state/codex}")"
export GH_CONFIG_DIR="$(to_abs "${WORKSPACE_GH_STATE_DIR:-./.state/gh}")"
export GLAB_CONFIG_DIR="$(to_abs "${WORKSPACE_GLAB_STATE_DIR:-./.state/glab}")"
export HISTFILE="$(to_abs "${WORKSPACE_COMMAND_HISTORY_DIR:-./.state/commandhistory}")/.zsh_history"

mkdir -p "${WORKSPACE_REPOS}" "${CODEX_HOME}" "$(dirname "${HISTFILE}")"

shell_path="${SHELL:-/usr/bin/zsh}"
if [ ! -x "${shell_path}" ]; then
  shell_path="$(command -v zsh || command -v bash)"
fi

exec "${shell_path}" -l
