#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: bash scripts/restore-workspace.sh [--force] [--dry-run] BACKUP_ARCHIVE

Restores a backup created by scripts/backup-workspace.sh. The platform .env is
restored into the platform repo; workspace-root/* is restored into WORKSPACE_ROOT.
Codex should not be running while restore is applied. Existing runtime state is
refused by default. With --force, existing state is moved to WORKSPACE_ROOT/backups
before the archive is extracted.
USAGE
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "${repo_root}"

force=0
dry_run=0
archive=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --force)
      force=1
      shift
      ;;
    --dry-run)
      dry_run=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      fail "unknown argument: $1"
      ;;
    *)
      [ -z "${archive}" ] || fail "only one backup archive may be provided"
      archive="$1"
      shift
      ;;
  esac
done

[ -n "${archive}" ] || fail "backup archive is required"
[ -f "${archive}" ] || fail "backup archive not found: ${archive}"

archive_abs="$(realpath -m "${archive}")"

if command -v pgrep >/dev/null 2>&1 && pgrep -u "$(id -u)" -x codex >/dev/null 2>&1; then
  fail "codex is running for user $(id -un); close it before restore"
fi

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "${tmp_dir}"
}
trap cleanup EXIT

members="${tmp_dir}/members.txt"
tar -tzf "${archive_abs}" >"${members}" || fail "archive is not a readable tar.gz file"

grep -qx 'backup-metadata/manifest.txt' "${members}" || fail "archive is missing backup-metadata/manifest.txt"
grep -qx '.env' "${members}" || fail "archive is missing .env"

member_prefix_exists() {
  local prefix="$1"
  awk -v prefix="${prefix}" '
    $0 == prefix || index($0, prefix "/") == 1 { found = 1; exit }
    END { exit !found }
  ' "${members}"
}

while IFS= read -r member; do
  [ -n "${member}" ] || fail "archive contains an empty path"
  case "${member}" in
    /*|../*|*/../*|*/..)
      fail "archive contains an unsafe path: ${member}"
      ;;
  esac

  case "${member}" in
    .env|workspace-root|workspace-root/*|.state|.state/*|workspace|workspace/repos|workspace/repos/*|backup-metadata|backup-metadata/*)
      ;;
    *)
      fail "archive contains an unexpected path: ${member}"
      ;;
  esac
done <"${members}"

archive_layout="legacy-repo-root"
if member_prefix_exists "workspace-root"; then
  archive_layout="workspace-root-v2"
elif ! member_prefix_exists ".state" && ! member_prefix_exists "workspace/repos"; then
  fail "archive does not contain workspace-root/* or legacy repo-local workspace state"
fi

env_extract_dir="${tmp_dir}/env"
mkdir -p "${env_extract_dir}"
tar -xzf "${archive_abs}" -C "${env_extract_dir}" .env

set -a
# shellcheck disable=SC1091
. "${env_extract_dir}/.env"
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
elif [ "${archive_layout}" = "legacy-repo-root" ] \
  || [ -n "${WORKSPACE_REPOS_DIR:-}" ] \
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
backup_dir_abs="${workspace_root_abs}/backups"

to_workspace_relative() {
  local raw="$1"
  local abs
  local rel

  [ -n "${raw}" ] || fail "empty path is not allowed"

  case "${raw}" in
    *$'\n'*)
      fail "path contains a newline and cannot be restored safely: ${raw}"
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
      fail "persistent path is outside WORKSPACE_ROOT (${workspace_root_abs}) and is not supported by this restore script: ${raw}"
      ;;
  esac

  case "${rel}" in
    ""|.|-*|*'/../'*|../*|*/..)
      fail "unsafe relative restore path: ${rel}"
      ;;
  esac

  printf '%s\n' "${rel}"
}

has_content() {
  local path="$1"
  if [ ! -e "${path}" ]; then
    return 1
  fi
  if [ -f "${path}" ] || [ -L "${path}" ]; then
    return 0
  fi
  find "${path}" -mindepth 1 -print -quit | grep -q .
}

restore_labels=()
conflict_labels=()
conflict_paths=()

add_restore_target() {
  local label="$1"
  local path="$2"

  restore_labels+=("${label}")
  if has_content "${path}"; then
    conflict_labels+=("${label}")
    conflict_paths+=("${path}")
  fi
}

add_workspace_target_if_present() {
  local raw="$1"
  local rel
  local label

  rel="$(to_workspace_relative "${raw}")"
  label="workspace-root/${rel}"
  if member_prefix_exists "${label}"; then
    add_restore_target "${label}" "${workspace_root_abs}/${rel}"
  fi
}

add_restore_target ".env" "${repo_root}/.env"

if [ "${archive_layout}" = "workspace-root-v2" ]; then
  add_workspace_target_if_present "${WORKSPACE_REPOS_DIR:-${workspace_root_abs}/repos}"
  add_workspace_target_if_present "${WORKSPACE_CODEX_STATE_DIR:-${workspace_root_abs}/state/codex}"
  add_workspace_target_if_present "${WORKSPACE_GH_STATE_DIR:-${workspace_root_abs}/state/gh}"
  add_workspace_target_if_present "${WORKSPACE_GLAB_STATE_DIR:-${workspace_root_abs}/state/glab}"
  add_workspace_target_if_present "${WORKSPACE_SSH_STATE_DIR:-${workspace_root_abs}/state/ssh}"
  add_workspace_target_if_present "${WORKSPACE_COMMAND_HISTORY_DIR:-${workspace_root_abs}/state/commandhistory}"
else
  member_prefix_exists ".state" && add_restore_target ".state" "${repo_root}/.state"
  member_prefix_exists "workspace/repos" && add_restore_target "workspace/repos" "${repo_root}/workspace/repos"
fi

if [ "${#conflict_labels[@]}" -gt 0 ] && [ "${force}" -ne 1 ] && [ "${dry_run}" -ne 1 ]; then
  printf 'ERROR: restore would overwrite existing runtime state:\n' >&2
  printf '  %s\n' "${conflict_labels[@]}" >&2
  printf "Rerun with --force to move existing state into WORKSPACE_ROOT/backups/pre-restore-* first.\n" >&2
  exit 1
fi

echo "Backup archive: ${archive_abs}"
echo "Archive layout: ${archive_layout}"
echo "Workspace root: ${workspace_root_abs}"
if [ "${#conflict_labels[@]}" -gt 0 ]; then
  echo "Existing runtime state:"
  printf '  %s\n' "${conflict_labels[@]}"
fi
echo "Runtime paths to restore:"
for label in "${restore_labels[@]}"; do
  echo "  ${label}"
done

if [ "${dry_run}" -eq 1 ]; then
  echo "Dry run complete; no files were changed."
  exit 0
fi

if [ "${#conflict_labels[@]}" -gt 0 ]; then
  timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
  pre_restore_dir="${backup_dir_abs}/pre-restore-${timestamp}"
  mkdir -p "${pre_restore_dir}"
  for i in "${!conflict_labels[@]}"; do
    label="${conflict_labels[$i]}"
    path="${conflict_paths[$i]}"
    mkdir -p "${pre_restore_dir}/$(dirname "${label}")"
    mv "${path}" "${pre_restore_dir}/${label}"
  done
  echo "Moved existing runtime state to: ${pre_restore_dir}"
fi

mkdir -p "${workspace_root_abs}"

tar -xzf "${archive_abs}" -C "${repo_root}" --no-same-owner .env

if [ "${archive_layout}" = "workspace-root-v2" ]; then
  tar -xzf "${archive_abs}" \
    -C "${workspace_root_abs}" \
    --no-same-owner \
    --strip-components=1 \
    --wildcards 'workspace-root/*'
else
  tar -xzf "${archive_abs}" \
    -C "${repo_root}" \
    --no-same-owner \
    --exclude='.env' \
    --exclude='backup-metadata' \
    --exclude='backup-metadata/*'
fi

restore_meta_dir="${backup_dir_abs}/restore-metadata/$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "${restore_meta_dir}"
tar -xzf "${archive_abs}" -C "${restore_meta_dir}" --no-same-owner backup-metadata

echo "Restore complete."
echo "Backup metadata copied to: ${restore_meta_dir}/backup-metadata"
echo "Next: bash scripts/start-workspace.sh && bash scripts/check-workspace.sh"
