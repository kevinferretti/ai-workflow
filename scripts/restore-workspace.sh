#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: bash scripts/restore-workspace.sh [--force] [--dry-run] BACKUP_ARCHIVE

Restores a backup created by scripts/backup-workspace.sh into the platform repo.
The workspace container must be stopped. Existing runtime state is refused by
default. With --force, existing state is moved to backups/pre-restore-* before
the archive is extracted.
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

container_id="$(docker compose ps -q workspace 2>/dev/null || true)"
if [ -n "${container_id}" ]; then
  running="$(docker inspect -f '{{.State.Running}}' "${container_id}" 2>/dev/null || echo false)"
  [ "${running}" != "true" ] || fail "workspace is running; stop it with 'docker compose stop workspace' before restore"
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

while IFS= read -r member; do
  [ -n "${member}" ] || fail "archive contains an empty path"
  case "${member}" in
    /*|../*|*/../*|*/..)
      fail "archive contains an unsafe path: ${member}"
      ;;
  esac

  case "${member}" in
    .env|.state|.state/*|workspace|workspace/repos|workspace/repos/*|backup-metadata|backup-metadata/*)
      ;;
    *)
      fail "archive contains an unexpected path: ${member}"
      ;;
  esac
done <"${members}"

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

conflicts=()
for target in ".env" ".state" "workspace/repos"; do
  if has_content "${target}"; then
    conflicts+=("${target}")
  fi
done

if [ "${#conflicts[@]}" -gt 0 ] && [ "${force}" -ne 1 ] && [ "${dry_run}" -ne 1 ]; then
  printf 'ERROR: restore would overwrite existing runtime state:\n' >&2
  printf '  %s\n' "${conflicts[@]}" >&2
  printf "Rerun with --force to move existing state into backups/pre-restore-* first.\n" >&2
  exit 1
fi

echo "Backup archive: ${archive_abs}"
if [ "${#conflicts[@]}" -gt 0 ]; then
  echo "Existing runtime state:"
  printf '  %s\n' "${conflicts[@]}"
fi
echo "Runtime paths to restore:"
for target in ".env" ".state/codex" ".state/gh" ".state/ssh" ".state/commandhistory" "workspace/repos"; do
  if grep -Eq "^${target//\./\\.}($|/)" "${members}"; then
    echo "  ${target}"
  fi
done

if [ "${dry_run}" -eq 1 ]; then
  echo "Dry run complete; no files were changed."
  exit 0
fi

if [ "${#conflicts[@]}" -gt 0 ]; then
  timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
  pre_restore_dir="backups/pre-restore-${timestamp}"
  mkdir -p "${pre_restore_dir}"
  for target in "${conflicts[@]}"; do
    mkdir -p "${pre_restore_dir}/$(dirname "${target}")"
    mv "${target}" "${pre_restore_dir}/${target}"
  done
  echo "Moved existing runtime state to: ${pre_restore_dir}"
fi

tar -xzf "${archive_abs}" \
  -C "${repo_root}" \
  --no-same-owner \
  --exclude='backup-metadata' \
  --exclude='backup-metadata/*'

restore_meta_dir="backups/restore-metadata/$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "${restore_meta_dir}"
tar -xzf "${archive_abs}" -C "${restore_meta_dir}" --no-same-owner backup-metadata

echo "Restore complete."
echo "Backup metadata copied to: ${restore_meta_dir}/backup-metadata"
echo "Next: bash scripts/start-workspace.sh && bash scripts/check-workspace.sh"
