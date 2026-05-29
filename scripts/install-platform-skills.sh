#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

usage() {
  cat <<'USAGE'
Usage: bash scripts/install-platform-skills.sh

Installs this repo's requirements workflow skills into $CODEX_HOME/skills.
USAGE
}

if [ "$#" -gt 0 ]; then
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "unknown argument: $1"
      ;;
  esac
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
platform_root="${PLATFORM_ROOT:-${repo_root}}"
source_dir="${platform_root}/skills"
codex_home="${CODEX_HOME:-${HOME}/.codex}"
dest_dir="${codex_home}/skills"

[ -d "${source_dir}" ] || fail "skills source directory not found: ${source_dir}"

mkdir -p "${dest_dir}"

installed=0
for skill_dir in "${source_dir}"/requirements-workflow-*; do
  [ -d "${skill_dir}" ] || continue
  skill_name="$(basename "${skill_dir}")"
  target="${dest_dir}/${skill_name}"

  rm -rf "${target}"
  cp -a "${skill_dir}" "${target}"
  installed=$((installed + 1))
done

[ "${installed}" -gt 0 ] || fail "no requirements workflow skill directories found in ${source_dir}"

echo "Installed ${installed} requirements workflow skill directories into ${dest_dir}"
