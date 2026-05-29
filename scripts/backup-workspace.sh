#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: bash scripts/backup-workspace.sh [--live] [--output-dir DIR] [--prefix NAME]

Creates a timestamped tar.gz archive containing the persistent host workspace
runtime state:

  .env
  workspace-root/repos
  workspace-root/state/codex
  workspace-root/state/gh
  workspace-root/state/glab
  workspace-root/state/ssh
  workspace-root/state/commandhistory

By default the script refuses to back up while Codex is running for the current
user. Use --live only when you accept a potentially inconsistent snapshot.
USAGE
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

warn() {
  echo "WARN: $*" >&2
}

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "${repo_root}"

backup_dir=""
backup_prefix=""
allow_live=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --live)
      allow_live=1
      shift
      ;;
    --output-dir)
      [ "$#" -ge 2 ] || fail "--output-dir requires a value"
      backup_dir="$2"
      shift 2
      ;;
    --prefix)
      [ "$#" -ge 2 ] || fail "--prefix requires a value"
      backup_prefix="$2"
      shift 2
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

[ -f .env ] || fail ".env is required; run 'cp .env.example .env' and 'bash scripts/start-workspace.sh' first"

set -a
# shellcheck disable=SC1091
. ./.env
set +a

to_abs() {
  local raw="$1"
  case "${raw}" in
    "~")
      realpath -m "${HOME}"
      ;;
    "~/"*)
      realpath -m "${HOME}/${raw#~/}"
      ;;
    [A-Za-z]:*)
      fail "Windows-style absolute paths are not supported on the Linux VM: ${raw}"
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

workspace_root_abs="$(realpath -m "${workspace_root}")"
backup_dir="${backup_dir:-${BACKUP_DIR:-${workspace_root_abs}/backups}}"
backup_prefix="${backup_prefix:-${BACKUP_PREFIX:-workspace}}"

codex_running=false
if command -v pgrep >/dev/null 2>&1 && pgrep -u "$(id -u)" -x codex >/dev/null 2>&1; then
  codex_running=true
  if [ "${allow_live}" -ne 1 ]; then
    fail "codex is running for user $(id -un); close it before backup, or rerun with --live"
  fi
fi

to_workspace_relative() {
  local raw="$1"
  local abs
  local rel

  [ -n "${raw}" ] || fail "empty path is not allowed"

  case "${raw}" in
    *$'\n'*)
      fail "path contains a newline and cannot be archived safely: ${raw}"
      ;;
  esac

  abs="$(to_abs "${raw}")"
  case "${abs}" in
    "${workspace_root_abs}")
      rel="."
      ;;
    "${workspace_root_abs}"/*)
      rel="${abs#${workspace_root_abs}/}"
      ;;
    *)
      fail "persistent path is outside WORKSPACE_ROOT (${workspace_root_abs}) and is not supported by this backup script: ${raw}"
      ;;
  esac

  case "${rel}" in
    ""|.|-*|*'/../'*|../*|*/..)
      fail "unsafe relative backup path: ${rel}"
      ;;
  esac

  printf '%s\n' "${rel}"
}

configured_paths=(
  "${WORKSPACE_REPOS_DIR:-${workspace_root_abs}/repos}"
  "${WORKSPACE_CODEX_STATE_DIR:-${workspace_root_abs}/state/codex}"
  "${WORKSPACE_GH_STATE_DIR:-${workspace_root_abs}/state/gh}"
  "${WORKSPACE_GLAB_STATE_DIR:-${workspace_root_abs}/state/glab}"
  "${WORKSPACE_SSH_STATE_DIR:-${workspace_root_abs}/state/ssh}"
  "${WORKSPACE_COMMAND_HISTORY_DIR:-${workspace_root_abs}/state/commandhistory}"
)

timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
backup_dir_abs="$(to_abs "${backup_dir}")"
mkdir -p "${backup_dir_abs}"

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "${tmp_dir}"
}
trap cleanup EXIT

filelist="${tmp_dir}/files.txt"
: >"${filelist}"

for path in "${configured_paths[@]}"; do
  rel="$(to_workspace_relative "${path}")"
  if [ -e "${workspace_root_abs}/${rel}" ]; then
    printf '%s\n' "${rel}" >>"${filelist}"
  else
    warn "skipping missing path: workspace-root/${rel}"
  fi
done

[ -s "${filelist}" ] || fail "no workspace state paths exist to back up"

metadata_dir="${tmp_dir}/backup-metadata"
mkdir -p "${metadata_dir}"

{
  echo "created_utc=${timestamp}"
  echo "archive_format=tar.gz"
  echo "archive_layout=workspace-root-v2"
  echo "workspace_model=direct-host"
  echo "repo_root=${repo_root}"
  echo "workspace_root=${workspace_root_abs}"
  echo "workspace_user=${WORKSPACE_USER:-codex}"
  echo "codex_processes_running=${codex_running}"
  echo "platform_git_branch=$(git branch --show-current 2>/dev/null || true)"
  echo "platform_git_commit=$(git rev-parse HEAD 2>/dev/null || true)"
  if git diff --quiet --ignore-submodules -- 2>/dev/null && git diff --cached --quiet --ignore-submodules -- 2>/dev/null; then
    echo "platform_git_dirty=false"
  else
    echo "platform_git_dirty=true"
  fi
  echo
  echo "included_paths:"
  echo "- .env"
  sed 's|^|- workspace-root/|' "${filelist}"
  echo
  echo "excluded_paths:"
  echo "- workspace-root/state/codex/tmp"
} >"${metadata_dir}/manifest.txt"

{
  command -v codex >/dev/null 2>&1 && codex --version || true
  command -v node >/dev/null 2>&1 && node --version || true
  command -v npm >/dev/null 2>&1 && npm --version || true
  command -v git >/dev/null 2>&1 && git --version || true
  command -v gh >/dev/null 2>&1 && gh --version || true
  command -v glab >/dev/null 2>&1 && glab --version || true
} >"${metadata_dir}/tool-versions.txt" 2>/dev/null || true

git status --short >"${metadata_dir}/git-status.txt" 2>/dev/null || true

archive="${backup_dir_abs}/${backup_prefix}-${timestamp}.tar.gz"
archive_tmp="${archive}.tmp"
archive_tar="${tmp_dir}/archive.tar"

tar -cf "${archive_tar}" \
  -C "${repo_root}" .env \
  -C "${tmp_dir}" backup-metadata

tar -rf "${archive_tar}" \
  --exclude='state/codex/tmp' \
  --exclude='state/codex/tmp/*' \
  --transform='s,^,workspace-root/,' \
  -C "${workspace_root_abs}" -T "${filelist}"

gzip -c "${archive_tar}" >"${archive_tmp}"

mv "${archive_tmp}" "${archive}"
chmod 0600 "${archive}" 2>/dev/null || true

echo "Created backup: ${archive}"
echo "Treat this archive as sensitive; it may contain Codex, GitHub, GitLab, and SSH credentials."
