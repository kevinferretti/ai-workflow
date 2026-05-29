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
    "~")
      realpath -m "${HOME}"
      ;;
    "~/"*)
      realpath -m "${HOME}/${raw#~/}"
      ;;
    /*)
      realpath -m "${raw}"
      ;;
    *)
      realpath -m "${repo_root}/${raw#./}"
      ;;
  esac
}

if [ -n "${WORKSPACE_ROOT:-}" ]; then
  workspace_root="$(to_abs "${WORKSPACE_ROOT}")"
elif [ -n "${WORKSPACE_REPOS_DIR:-}" ] \
  || [ -n "${WORKSPACE_CODEX_STATE_DIR:-}" ] \
  || [ -n "${WORKSPACE_GH_STATE_DIR:-}" ] \
  || [ -n "${WORKSPACE_GLAB_STATE_DIR:-}" ] \
  || [ -n "${WORKSPACE_SSH_STATE_DIR:-}" ] \
  || [ -n "${WORKSPACE_COMMAND_HISTORY_DIR:-}" ]; then
  workspace_root="${repo_root}"
else
  workspace_root="$(to_abs "~/workspace")"
fi

export PLATFORM_ROOT="${repo_root}"
export WORKSPACE_ROOT="${workspace_root}"
export WORKSPACE_REPOS="$(to_abs "${WORKSPACE_REPOS_DIR:-${workspace_root}/repos}")"
export CODEX_HOME="$(to_abs "${WORKSPACE_CODEX_STATE_DIR:-${workspace_root}/state/codex}")"
export GH_CONFIG_DIR="$(to_abs "${WORKSPACE_GH_STATE_DIR:-${workspace_root}/state/gh}")"
export GLAB_CONFIG_DIR="$(to_abs "${WORKSPACE_GLAB_STATE_DIR:-${workspace_root}/state/glab}")"
export HISTFILE="$(to_abs "${WORKSPACE_COMMAND_HISTORY_DIR:-${workspace_root}/state/commandhistory}")/.zsh_history"

mkdir -p "${WORKSPACE_ROOT}" "${WORKSPACE_REPOS}" "${CODEX_HOME}" "$(dirname "${HISTFILE}")"

shell_path="${SHELL:-/usr/bin/zsh}"
if [ ! -x "${shell_path}" ]; then
  shell_path="$(command -v zsh || command -v bash)"
fi

exec "${shell_path}" -l
