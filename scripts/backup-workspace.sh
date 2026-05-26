#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: bash scripts/backup-workspace.sh [--live] [--output-dir DIR] [--prefix NAME]

Creates a timestamped tar.gz archive containing the persistent workspace
runtime state:

  .env
  .state/codex
  .state/gh
  .state/glab
  .state/ssh
  .state/commandhistory
  workspace/repos

By default the script refuses to back up while the workspace container is
running. Use --live only when you accept a potentially inconsistent snapshot.
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

backup_dir="${BACKUP_DIR:-backups}"
backup_prefix="${BACKUP_PREFIX:-workspace}"
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

[ -f .env ] || fail ".env is required; run 'cp .env.example .env' and start the workspace first"

set -a
# shellcheck disable=SC1091
. ./.env
set +a

container_id="$(docker compose ps -q workspace 2>/dev/null || true)"
running=false
if [ -n "${container_id}" ]; then
  running="$(docker inspect -f '{{.State.Running}}' "${container_id}" 2>/dev/null || echo false)"
  if [ "${running}" = "true" ] && [ "${allow_live}" -ne 1 ]; then
    fail "workspace is running; stop it with 'docker compose stop workspace' before backup, or rerun with --live"
  fi
fi

repo_abs="$(realpath -m "${repo_root}")"

to_repo_relative() {
  local raw="$1"
  local candidate
  local abs
  local rel

  [ -n "${raw}" ] || fail "empty path is not allowed"

  case "${raw}" in
    *$'\n'*)
      fail "path contains a newline and cannot be archived safely: ${raw}"
      ;;
    /*)
      candidate="${raw}"
      ;;
    [A-Za-z]:*)
      fail "Windows-style absolute paths are not supported on the Linux VM: ${raw}"
      ;;
    *)
      candidate="${repo_root}/${raw#./}"
      ;;
  esac

  abs="$(realpath -m "${candidate}")"
  case "${abs}" in
    "${repo_abs}")
      rel="."
      ;;
    "${repo_abs}"/*)
      rel="${abs#${repo_abs}/}"
      ;;
    *)
      fail "persistent path is outside the platform repo and is not supported by this backup script: ${raw}"
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
  ".env"
  "${WORKSPACE_REPOS_DIR:-./workspace/repos}"
  "${WORKSPACE_CODEX_STATE_DIR:-./.state/codex}"
  "${WORKSPACE_GH_STATE_DIR:-./.state/gh}"
  "${WORKSPACE_GLAB_STATE_DIR:-./.state/glab}"
  "${WORKSPACE_SSH_STATE_DIR:-./.state/ssh}"
  "${WORKSPACE_COMMAND_HISTORY_DIR:-./.state/commandhistory}"
)

timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
backup_dir_abs="$(realpath -m "${backup_dir}")"
mkdir -p "${backup_dir_abs}"

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "${tmp_dir}"
}
trap cleanup EXIT

filelist="${tmp_dir}/files.txt"
: >"${filelist}"

for path in "${configured_paths[@]}"; do
  rel="$(to_repo_relative "${path}")"
  if [ -e "${repo_root}/${rel}" ]; then
    printf '%s\n' "${rel}" >>"${filelist}"
  else
    warn "skipping missing path: ${rel}"
  fi
done

[ -s "${filelist}" ] || fail "no workspace state paths exist to back up"

metadata_dir="${tmp_dir}/backup-metadata"
mkdir -p "${metadata_dir}"

{
  echo "created_utc=${timestamp}"
  echo "archive_format=tar.gz"
  echo "repo_root=${repo_root}"
  echo "compose_project_name=${COMPOSE_PROJECT_NAME:-ai-workflow}"
  echo "workspace_container_running=${running}"
  echo "platform_git_branch=$(git branch --show-current 2>/dev/null || true)"
  echo "platform_git_commit=$(git rev-parse HEAD 2>/dev/null || true)"
  if git diff --quiet --ignore-submodules -- 2>/dev/null && git diff --cached --quiet --ignore-submodules -- 2>/dev/null; then
    echo "platform_git_dirty=false"
  else
    echo "platform_git_dirty=true"
  fi
  echo
  echo "included_paths:"
  sed 's/^/- /' "${filelist}"
  echo
  echo "excluded_paths:"
  echo "- .state/codex/tmp"
} >"${metadata_dir}/manifest.txt"

docker compose config >"${metadata_dir}/docker-compose.config.yml" 2>"${metadata_dir}/docker-compose.config.stderr" || true
git status --short >"${metadata_dir}/git-status.txt" 2>/dev/null || true

archive="${backup_dir_abs}/${backup_prefix}-${timestamp}.tar.gz"
archive_tmp="${archive}.tmp"

tar -czf "${archive_tmp}" \
  --exclude='.state/codex/tmp' \
  --exclude='.state/codex/tmp/*' \
  -C "${repo_root}" -T "${filelist}" \
  -C "${tmp_dir}" backup-metadata

mv "${archive_tmp}" "${archive}"
chmod 0600 "${archive}" 2>/dev/null || true

echo "Created backup: ${archive}"
echo "Treat this archive as sensitive; it may contain Codex, GitHub, and SSH credentials."
