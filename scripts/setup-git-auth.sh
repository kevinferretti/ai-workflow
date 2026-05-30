#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: bash scripts/setup-git-auth.sh [--non-interactive] [--require-auth] [--skip-github] [--skip-gitlab]

Authenticates GitHub and GitLab CLIs when tokens are available, configures Git
helpers, and optionally uploads the workspace SSH key to both accounts.

Token inputs, in priority order:
  GitHub: GITHUB_TOKEN_FILE, GITHUB_AUTH_TOKEN_FILE, GH_TOKEN, GITHUB_TOKEN
  GitLab: GITLAB_TOKEN_FILE, GITLAB_AUTH_TOKEN_FILE, GITLAB_TOKEN, GITLAB_ACCESS_TOKEN
USAGE
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

warn() {
  echo "WARN: $*" >&2
}

info() {
  echo "$*" >&2
}

non_interactive=0
require_auth_arg=0
skip_github=0
skip_gitlab=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --non-interactive)
      non_interactive=1
      shift
      ;;
    --require-auth)
      require_auth_arg=1
      shift
      ;;
    --skip-github)
      skip_github=1
      shift
      ;;
    --skip-gitlab)
      skip_gitlab=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "unknown argument: $1"
      ;;
  esac
done

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "${repo_root}"

[ -f .env ] || fail ".env is required; run 'cp .env.example .env' first"

set -a
# shellcheck disable=SC1091
. ./.env
set +a

workspace_user="${WORKSPACE_USER:-codex}"
[ "$(id -u)" -ne 0 ] || fail "run this as ${workspace_user}, not root"
if [ "$(id -un)" != "${workspace_user}" ]; then
  fail "run this as ${workspace_user}, or set WORKSPACE_USER=$(id -un) in .env"
fi

to_abs() {
  local raw="$1"
  case "${raw}" in
    "")
      printf ''
      ;;
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

gh_state="$(to_abs "${WORKSPACE_GH_STATE_DIR:-${workspace_root}/state/gh}")"
glab_state="$(to_abs "${WORKSPACE_GLAB_STATE_DIR:-${workspace_root}/state/glab}")"
ssh_state="$(to_abs "${WORKSPACE_SSH_STATE_DIR:-${workspace_root}/state/ssh}")"

mkdir -p "${gh_state}" "${glab_state}" "${ssh_state}" "${HOME}/.config"
chmod 0700 "${gh_state}" "${glab_state}" "${ssh_state}" 2>/dev/null || true

export GH_CONFIG_DIR="${gh_state}"
export GLAB_CONFIG_DIR="${glab_state}"

strip_host() {
  local raw="$1"
  raw="${raw#https://}"
  raw="${raw#http://}"
  raw="${raw%%/*}"
  printf '%s\n' "${raw}"
}

read_token() {
  local file_var
  local value
  local file

  while [ "$#" -gt 0 ] && [ "$1" != "--" ]; do
    file_var="$1"
    value="${!file_var:-}"
    if [ -n "${value}" ]; then
      file="$(to_abs "${value}")"
      [ -f "${file}" ] || fail "${file_var} points to a missing file: ${file}"
      sed -n '1p' "${file}" | tr -d '\r\n'
      return 0
    fi
    shift
  done

  [ "$#" -gt 0 ] && shift

  while [ "$#" -gt 0 ]; do
    value="${!1:-}"
    if [ -n "${value}" ]; then
      printf '%s' "${value}"
      return 0
    fi
    shift
  done

  return 1
}

configure_git_identity() {
  if [ -n "${GIT_USER_NAME:-}" ]; then
    git config --global user.name "${GIT_USER_NAME}"
  fi
  if [ -n "${GIT_USER_EMAIL:-}" ]; then
    git config --global user.email "${GIT_USER_EMAIL}"
  fi
}

ssh_key_file=""
ssh_key_pub_file=""
ssh_key_title=""

ensure_ssh_key() {
  local key_comment
  local key_dir

  ssh_key_file="$(to_abs "${WORKSPACE_GIT_SSH_KEY_FILE:-${ssh_state}/id_ed25519_ai_workflow}")"
  ssh_key_pub_file="${ssh_key_file}.pub"
  ssh_key_title="${WORKSPACE_GIT_SSH_KEY_TITLE:-$(hostname 2>/dev/null || echo host)-ai-workflow}"
  key_comment="${WORKSPACE_GIT_SSH_KEY_COMMENT:-${workspace_user}@$(hostname 2>/dev/null || echo host)}"
  key_dir="$(dirname "${ssh_key_file}")"

  mkdir -p "${key_dir}"
  chmod 0700 "${key_dir}" 2>/dev/null || true

  if [ ! -f "${ssh_key_file}" ]; then
    info "Creating workspace SSH key: ${ssh_key_file}"
    ssh-keygen -t ed25519 -a 100 -N "" -C "${key_comment}" -f "${ssh_key_file}" >/dev/null
  fi

  [ -f "${ssh_key_pub_file}" ] || ssh-keygen -y -f "${ssh_key_file}" >"${ssh_key_pub_file}"
  chmod 0600 "${ssh_key_file}" 2>/dev/null || true
  chmod 0644 "${ssh_key_pub_file}" 2>/dev/null || true
}

write_ssh_config() {
  local github_host="$1"
  local gitlab_host="$2"
  local gitlab_ssh_host="$3"
  local config_file="${ssh_state}/config"
  local tmp_file
  local begin="# ai-workflow managed git hosts begin"
  local end="# ai-workflow managed git hosts end"

  [ -n "${ssh_key_file}" ] || ensure_ssh_key
  touch "${config_file}"
  chmod 0600 "${config_file}" 2>/dev/null || true

  tmp_file="$(mktemp)"
  awk -v begin="${begin}" -v end="${end}" '
    $0 == begin { skip = 1; next }
    $0 == end { skip = 0; next }
    skip != 1 { print }
  ' "${config_file}" >"${tmp_file}"

  {
    printf '%s\n' "${begin}"
    printf 'Host %s\n' "${github_host}"
    printf '  HostName %s\n' "${github_host}"
    printf '  User git\n'
    printf '  IdentityFile %s\n' "${ssh_key_file}"
    printf '  IdentitiesOnly yes\n'
    printf '  StrictHostKeyChecking accept-new\n'
    if [ "${gitlab_host}" != "${github_host}" ]; then
      printf '\n'
      printf 'Host %s\n' "${gitlab_host}"
      printf '  HostName %s\n' "${gitlab_ssh_host:-${gitlab_host}}"
      printf '  User git\n'
      printf '  IdentityFile %s\n' "${ssh_key_file}"
      printf '  IdentitiesOnly yes\n'
      printf '  StrictHostKeyChecking accept-new\n'
    fi
    printf '%s\n' "${end}"
  } >>"${tmp_file}"

  mv "${tmp_file}" "${config_file}"
  chmod 0600 "${config_file}" 2>/dev/null || true
}

github_auth_ok() {
  local host="$1"
  gh auth status --hostname "${host}" >/dev/null 2>&1
}

gitlab_auth_ok() {
  local host="$1"
  glab auth status --hostname "${host}" >/dev/null 2>&1
}

setup_github() {
  local host="$1"
  local protocol="$2"
  local token=""
  local pub_key=""

  command -v gh >/dev/null 2>&1 || fail "gh is not installed; rerun scripts/bootstrap-ubuntu-host.sh"

  if ! github_auth_ok "${host}"; then
    token="$(read_token GITHUB_TOKEN_FILE GITHUB_AUTH_TOKEN_FILE -- GH_TOKEN GITHUB_TOKEN || true)"
    if [ -n "${token}" ]; then
      info "Authenticating GitHub CLI for ${host} from token input."
      printf '%s\n' "${token}" | gh auth login --hostname "${host}" --git-protocol "${protocol}" --skip-ssh-key --with-token
    elif [ "${non_interactive}" -eq 1 ]; then
      warn "GitHub auth is not configured and no GitHub token input was found."
    else
      gh auth login --hostname "${host}" --git-protocol "${protocol}" --skip-ssh-key --web
    fi
  fi

  if github_auth_ok "${host}"; then
    gh config set git_protocol "${protocol}" --host "${host}" >/dev/null
    gh auth setup-git --hostname "${host}" >/dev/null
    info "GitHub CLI and Git helper are configured for ${host}."

    if [ "${protocol}" = "ssh" ] && [ "${WORKSPACE_GIT_UPLOAD_SSH_KEY:-1}" = "1" ]; then
      ensure_ssh_key
      pub_key="$(cat "${ssh_key_pub_file}")"
      if GH_HOST="${host}" gh api user/keys --jq '.[].key' 2>/dev/null | grep -Fx "${pub_key}" >/dev/null 2>&1; then
        info "GitHub already has this workspace SSH key."
      elif ! GH_HOST="${host}" gh ssh-key add "${ssh_key_pub_file}" --title "${ssh_key_title}" --type authentication >/dev/null; then
        warn "could not upload SSH key to GitHub; add ${ssh_key_pub_file} manually if SSH clone/push fails"
      else
        info "Uploaded workspace SSH key to GitHub."
      fi
    fi
  fi
}

setup_gitlab() {
  local host="$1"
  local api_host="$2"
  local api_protocol="$3"
  local ssh_host="$4"
  local protocol="$5"
  local token=""
  local pub_key=""
  local -a login_args

  command -v glab >/dev/null 2>&1 || fail "glab is not installed; rerun scripts/bootstrap-ubuntu-host.sh"

  if ! gitlab_auth_ok "${host}"; then
    token="$(read_token GITLAB_TOKEN_FILE GITLAB_AUTH_TOKEN_FILE -- GITLAB_TOKEN GITLAB_ACCESS_TOKEN || true)"
    login_args=(auth login --hostname "${host}" --api-protocol "${api_protocol}" --git-protocol "${protocol}")
    [ -n "${api_host}" ] && login_args+=(--api-host "${api_host}")
    [ -n "${ssh_host}" ] && login_args+=(--ssh-hostname "${ssh_host}")

    if [ -n "${token}" ]; then
      info "Authenticating GitLab CLI for ${host} from token input."
      printf '%s\n' "${token}" | glab "${login_args[@]}" --stdin
    elif [ "${non_interactive}" -eq 1 ]; then
      warn "GitLab auth is not configured and no GitLab token input was found."
    else
      glab "${login_args[@]}"
    fi
  fi

  if gitlab_auth_ok "${host}"; then
    git config --global credential."https://${host}".helper "!glab auth git-credential"
    info "GitLab CLI and Git helper are configured for ${host}."

    if [ "${protocol}" = "ssh" ] && [ "${WORKSPACE_GIT_UPLOAD_SSH_KEY:-1}" = "1" ]; then
      ensure_ssh_key
      pub_key="$(cat "${ssh_key_pub_file}")"
      if command -v jq >/dev/null 2>&1 && GITLAB_HOST="${host}" glab api user/keys 2>/dev/null | jq -r '.[].key' | grep -Fx "${pub_key}" >/dev/null 2>&1; then
        info "GitLab already has this workspace SSH key."
      elif ! GITLAB_HOST="${host}" glab ssh-key add "${ssh_key_pub_file}" --title "${ssh_key_title}" --usage-type auth >/dev/null 2>&1; then
        warn "could not upload SSH key to GitLab; it may already exist, or add ${ssh_key_pub_file} manually if SSH clone/push fails"
      else
        info "Uploaded workspace SSH key to GitLab."
      fi
    fi
  fi
}

github_host="$(strip_host "${GITHUB_HOST:-github.com}")"
github_protocol="${GITHUB_GIT_PROTOCOL:-ssh}"
gitlab_host="$(strip_host "${GITLAB_HOST:-labs.gauntletai.com}")"
gitlab_api_host="$(strip_host "${GITLAB_API_HOST:-}")"
gitlab_api_protocol="${GITLAB_API_PROTOCOL:-https}"
gitlab_ssh_host="$(strip_host "${GITLAB_SSH_HOST:-}")"
gitlab_protocol="${GITLAB_GIT_PROTOCOL:-ssh}"
require_auth="${WORKSPACE_REQUIRE_GIT_AUTH:-0}"
[ "${require_auth_arg}" -eq 1 ] && require_auth=1

case "${github_protocol}" in ssh|https) ;; *) fail "GITHUB_GIT_PROTOCOL must be ssh or https" ;; esac
case "${gitlab_protocol}" in ssh|https|http) ;; *) fail "GITLAB_GIT_PROTOCOL must be ssh, https, or http" ;; esac
case "${gitlab_api_protocol}" in https|http) ;; *) fail "GITLAB_API_PROTOCOL must be https or http" ;; esac

configure_git_identity

if [ "${github_protocol}" = "ssh" ] || [ "${gitlab_protocol}" = "ssh" ]; then
  ensure_ssh_key
  write_ssh_config "${github_host}" "${gitlab_host}" "${gitlab_ssh_host}"
fi

[ "${skip_github}" -eq 1 ] || setup_github "${github_host}" "${github_protocol}"
[ "${skip_gitlab}" -eq 1 ] || setup_gitlab "${gitlab_host}" "${gitlab_api_host}" "${gitlab_api_protocol}" "${gitlab_ssh_host}" "${gitlab_protocol}"

missing=0
if [ "${skip_github}" -ne 1 ] && ! github_auth_ok "${github_host}"; then
  missing=1
fi
if [ "${skip_gitlab}" -ne 1 ] && ! gitlab_auth_ok "${gitlab_host}"; then
  missing=1
fi

if [ "${missing}" -eq 1 ] && [ "${require_auth}" = "1" ]; then
  fail "required GitHub/GitLab authentication is incomplete"
fi

info "Git hosting auth setup finished."
