#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "${repo_root}"

[ -f .env ] || fail ".env is required; run 'cp .env.example .env' first"

set -a
# shellcheck disable=SC1091
. ./.env
set +a

workspace_user="${WORKSPACE_USER:-codex}"
[ "$(id -u)" -ne 0 ] || fail "workspace check must not run as root"
[ "$(id -un)" = "${workspace_user}" ] || fail "workspace check must run as ${workspace_user}; current user is $(id -un)"

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

echo "Workspace user: $(id -un)"
echo "Platform repo: ${repo_root}"
echo "Workspace root: ${workspace_root}"
echo "Additional repos: ${workspace_repos}"

for command_name in bash codex node npm git python3 rg gh glab; do
  command -v "${command_name}" >/dev/null 2>&1 || fail "${command_name} is not installed"
done

codex --version
node --version
npm --version
git --version
python3 --version

[ -d "${workspace_repos}" ] || fail "workspace repos directory does not exist: ${workspace_repos}"
[ -w "${workspace_repos}" ] || fail "workspace repos directory is not writable: ${workspace_repos}"

[ -d "${codex_state}" ] || fail "Codex state directory does not exist: ${codex_state}"
[ -d "${gh_state}" ] || fail "GitHub CLI state directory does not exist: ${gh_state}"
[ -d "${glab_state}" ] || fail "GitLab CLI state directory does not exist: ${glab_state}"
[ -d "${ssh_state}" ] || fail "SSH state directory does not exist: ${ssh_state}"
[ -d "${history_state}" ] || fail "command history directory does not exist: ${history_state}"

[ "$(realpath -m "${HOME}/.codex")" = "${codex_state}" ] || fail "${HOME}/.codex is not linked to ${codex_state}"
[ "$(realpath -m "${HOME}/.config/gh")" = "${gh_state}" ] || fail "${HOME}/.config/gh is not linked to ${gh_state}"
[ "$(realpath -m "${HOME}/.config/glab-cli")" = "${glab_state}" ] || fail "${HOME}/.config/glab-cli is not linked to ${glab_state}"
[ "$(realpath -m "${HOME}/.ssh")" = "${ssh_state}" ] || fail "${HOME}/.ssh is not linked to ${ssh_state}"

[ -f "${codex_state}/config.toml" ] || fail "Codex config not found: ${codex_state}/config.toml"
grep -F "${repo_root}" "${codex_state}/config.toml" >/dev/null || fail "Codex config does not trust ${repo_root}"
grep -F "${workspace_repos}" "${codex_state}/config.toml" >/dev/null || fail "Codex config does not trust ${workspace_repos}"

[ -d "${codex_state}/skills/requirements-workflow-init" ] || fail "requirements workflow init skill is not installed"
[ -d "${codex_state}/skills/requirements-workflow-shared" ] || fail "requirements workflow shared skill is not installed"

echo "Workspace check passed."
