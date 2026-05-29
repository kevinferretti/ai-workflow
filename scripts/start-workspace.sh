#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

warn() {
  echo "WARN: $*" >&2
}

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "${repo_root}"

if [ ! -f .env ]; then
  cp .env.example .env
  echo "Created .env from .env.example"
fi

set -a
# shellcheck disable=SC1091
. ./.env
set +a

workspace_user="${WORKSPACE_USER:-codex}"

[ "$(id -u)" -ne 0 ] || fail "run this as ${workspace_user}, not root"
if [ "$(id -un)" != "${workspace_user}" ]; then
  fail "run this as ${workspace_user}, or set WORKSPACE_USER=$(id -un) in .env"
fi

command -v codex >/dev/null 2>&1 || fail "codex is not installed; run scripts/bootstrap-ubuntu-host.sh first"
command -v node >/dev/null 2>&1 || fail "node is not installed; run scripts/bootstrap-ubuntu-host.sh first"
command -v npm >/dev/null 2>&1 || fail "npm is not installed; run scripts/bootstrap-ubuntu-host.sh first"

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

workspace_repos="$(to_abs "${WORKSPACE_REPOS_DIR:-${workspace_root}/repos}")"
codex_state="$(to_abs "${WORKSPACE_CODEX_STATE_DIR:-${workspace_root}/state/codex}")"
gh_state="$(to_abs "${WORKSPACE_GH_STATE_DIR:-${workspace_root}/state/gh}")"
glab_state="$(to_abs "${WORKSPACE_GLAB_STATE_DIR:-${workspace_root}/state/glab}")"
ssh_state="$(to_abs "${WORKSPACE_SSH_STATE_DIR:-${workspace_root}/state/ssh}")"
history_state="$(to_abs "${WORKSPACE_COMMAND_HISTORY_DIR:-${workspace_root}/state/commandhistory}")"

mkdir -p \
  "${workspace_root}" \
  "${workspace_repos}" \
  "${codex_state}" \
  "${gh_state}" \
  "${glab_state}" \
  "${ssh_state}" \
  "${history_state}" \
  "${HOME}/.config"

chmod 0775 "${workspace_repos}" 2>/dev/null || true
chmod 0700 "${codex_state}" "${gh_state}" "${glab_state}" "${ssh_state}" 2>/dev/null || true
chmod 0775 "${history_state}" 2>/dev/null || true

migrate_dir_to_link() {
  local target="$1"
  local link="$2"
  local mode="$3"

  mkdir -p "${target}"
  chmod "${mode}" "${target}" 2>/dev/null || true

  if [ -L "${link}" ]; then
    if [ "$(realpath -m "${link}")" != "${target}" ]; then
      current_target="$(realpath -m "${link}")"
      if [ -e "${current_target}" ]; then
        fail "${link} points to ${current_target}, expected ${target}"
      fi
      rm -f "${link}"
      ln -s "${target}" "${link}"
    fi
    return
  fi

  if [ -e "${link}" ]; then
    [ -d "${link}" ] || fail "${link} exists and is not a directory"
    shopt -s dotglob nullglob
    local entries=("${link}"/*)
    shopt -u dotglob nullglob
    for entry in "${entries[@]}"; do
      local base
      base="$(basename "${entry}")"
      [ ! -e "${target}/${base}" ] || fail "cannot migrate ${link}; ${target}/${base} already exists"
      mv "${entry}" "${target}/"
    done
    rmdir "${link}" || fail "could not replace ${link} with a state symlink"
  fi

  ln -s "${target}" "${link}"
}

migrate_file_to_link() {
  local target="$1"
  local link="$2"

  touch "${target}"

  if [ -L "${link}" ]; then
    if [ "$(realpath -m "${link}")" != "${target}" ]; then
      current_target="$(realpath -m "${link}")"
      if [ -e "${current_target}" ]; then
        fail "${link} points to ${current_target}, expected ${target}"
      fi
      rm -f "${link}"
      ln -s "${target}" "${link}"
    fi
    return
  fi

  if [ -e "${link}" ]; then
    [ -f "${link}" ] || fail "${link} exists and is not a regular file"
    cat "${link}" >>"${target}"
    rm -f "${link}"
  fi

  ln -s "${target}" "${link}"
}

migrate_dir_to_link "${codex_state}" "${HOME}/.codex" 0700
migrate_dir_to_link "${gh_state}" "${HOME}/.config/gh" 0700
migrate_dir_to_link "${glab_state}" "${HOME}/.config/glab-cli" 0700
migrate_dir_to_link "${ssh_state}" "${HOME}/.ssh" 0700
migrate_file_to_link "${history_state}/.bash_history" "${HOME}/.bash_history"
migrate_file_to_link "${history_state}/.zsh_history" "${HOME}/.zsh_history"

write_codex_config() {
  local config_file="$1"
  cat >"${config_file}" <<EOF
#:schema https://developers.openai.com/codex/config-schema.json

approval_policy = "on-request"
sandbox_mode = "workspace-write"
web_search = "cached"
history.persistence = "save-all"
check_for_update_on_startup = false
project_root_markers = ["AGENTS.md", ".git"]

[sandbox_workspace_write]
writable_roots = ["${repo_root}", "${workspace_repos}"]
network_access = true

[features]
multi_agent = true
shell_snapshot = true
unified_exec = true

[projects."${repo_root}"]
trust_level = "trusted"

[projects."${workspace_repos}"]
trust_level = "trusted"
EOF
  chmod 0600 "${config_file}" 2>/dev/null || true
}

codex_config="${codex_state}/config.toml"
if [ ! -f "${codex_config}" ]; then
  write_codex_config "${codex_config}"
elif grep -F '/workspace/platform' "${codex_config}" >/dev/null && ! grep -F "${repo_root}" "${codex_config}" >/dev/null; then
  backup_config="${codex_config}.pre-host-migration-$(date -u +%Y%m%dT%H%M%SZ)"
  cp "${codex_config}" "${backup_config}"
  write_codex_config "${codex_config}"
  echo "Replaced container Codex config; previous config saved at ${backup_config}"
elif ! grep -F "${repo_root}" "${codex_config}" >/dev/null || ! grep -F "${workspace_repos}" "${codex_config}" >/dev/null; then
  backup_config="${codex_config}.pre-path-migration-$(date -u +%Y%m%dT%H%M%SZ)"
  cp "${codex_config}" "${backup_config}"
  write_codex_config "${codex_config}"
  echo "Replaced stale Codex path config; previous config saved at ${backup_config}"
else
  grep -F "${repo_root}" "${codex_config}" >/dev/null || warn "Codex config does not mention ${repo_root}"
  grep -F "${workspace_repos}" "${codex_config}" >/dev/null || warn "Codex config does not mention ${workspace_repos}"
fi

env_file="${HOME}/.ai-workflow-env"
cat >"${env_file}" <<EOF
# Generated by ${repo_root}/scripts/start-workspace.sh
export PLATFORM_ROOT="${repo_root}"
export WORKSPACE_ROOT="${workspace_root}"
export WORKSPACE_REPOS="${workspace_repos}"
export CODEX_HOME="${codex_state}"
export GH_CONFIG_DIR="${gh_state}"
export GLAB_CONFIG_DIR="${glab_state}"
export HISTFILE="${history_state}/.zsh_history"
export HISTSIZE=50000
export SAVEHIST=50000
EOF
chmod 0600 "${env_file}" 2>/dev/null || true

ensure_profile_source() {
  local profile="$1"
  touch "${profile}"
  if ! grep -F '. "${HOME}/.ai-workflow-env"' "${profile}" >/dev/null; then
    {
      echo
      echo '# AI workflow host workspace'
      echo '[ -f "${HOME}/.ai-workflow-env" ] && . "${HOME}/.ai-workflow-env"'
    } >>"${profile}"
  fi
}

ensure_profile_source "${HOME}/.profile"
ensure_profile_source "${HOME}/.bashrc"
ensure_profile_source "${HOME}/.zshrc"

CODEX_HOME="${codex_state}" PLATFORM_ROOT="${repo_root}" bash scripts/install-platform-skills.sh

echo "Host workspace is ready."
echo "Platform repo: ${repo_root}"
echo "Workspace root: ${workspace_root}"
echo "Additional repos: ${workspace_repos}"
echo "Open a shell with: bash scripts/workspace-shell.sh"
