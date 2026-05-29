#!/usr/bin/env bash
set -euo pipefail

warn() {
  echo "WARN: $*" >&2
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "${repo_root}"

if [ -f .env ]; then
  set -a
  # shellcheck disable=SC1091
  . ./.env
  set +a
fi

if [ "$(uname -s)" != "Linux" ]; then
  fail "host check must run on the Linux VM host"
fi

if [ -f /etc/os-release ]; then
  . /etc/os-release
else
  fail "/etc/os-release not found"
fi

if [ "${ID:-}" != "ubuntu" ]; then
  fail "unsupported host OS '${ID:-unknown}'; use Ubuntu 24.04 LTS for the MVP"
fi

echo "Host OS: ${PRETTY_NAME:-ubuntu}"

case "${VERSION_ID:-}" in
  24.04)
    ;;
  *)
    warn "expected Ubuntu 24.04 LTS; found VERSION_ID=${VERSION_ID:-unknown}"
    ;;
esac

mem_kib="$(awk '/MemTotal/ { print $2 }' /proc/meminfo)"
mem_mib="$((mem_kib / 1024))"
echo "Memory: ${mem_mib} MiB"
if [ "$mem_mib" -lt 3800 ]; then
  warn "less than 4 GiB RAM; Codex and builds may be constrained"
fi

available_mib="$(df -Pm . | awk 'NR == 2 { print $4 }')"
echo "Disk available at repo root: ${available_mib} MiB"
if [ "$available_mib" -lt 20000 ]; then
  warn "less than 20 GiB free at repo root; package caches and repos may fill the disk"
fi

command -v tailscale >/dev/null 2>&1 || fail "tailscale is not installed"

for command_name in codex node npm git python3 rg gh glab zsh; do
  command -v "${command_name}" >/dev/null 2>&1 || fail "${command_name} is not installed"
done

echo "Codex: $(codex --version)"
echo "Node: $(node --version)"
echo "npm: $(npm --version)"
echo "Git: $(git --version)"
echo "GitHub CLI: $(gh --version | head -n 1)"
echo "GitLab CLI: $(glab --version | head -n 1)"

if tailscale status >/dev/null 2>&1; then
  echo "Tailscale IPv4: $(tailscale ip -4 2>/dev/null || true)"
else
  fail "tailscale is installed but not connected; run 'sudo tailscale up --ssh'"
fi

workspace_user="${WORKSPACE_USER:-codex}"
if id -u "${workspace_user}" >/dev/null 2>&1; then
  echo "Workspace user: ${workspace_user}"
else
  fail "workspace user '${workspace_user}' does not exist"
fi

if command -v ss >/dev/null 2>&1; then
  echo "Listening TCP sockets:"
  ss -ltnp 2>/dev/null | awk 'NR == 1 || /:22[[:space:]]/ || /tailscaled/'
fi

echo "Host check passed."
