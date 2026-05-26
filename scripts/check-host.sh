#!/usr/bin/env bash
set -euo pipefail

warn() {
  echo "WARN: $*" >&2
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

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
  warn "less than 20 GiB free at repo root; Docker images and repos may fill the disk"
fi

command -v docker >/dev/null 2>&1 || fail "docker is not installed"
command -v tailscale >/dev/null 2>&1 || fail "tailscale is not installed"

docker info >/dev/null 2>&1 || fail "docker daemon is not reachable for user '${USER}'"
docker compose version >/dev/null 2>&1 || fail "docker compose plugin is not available"

echo "Docker: $(docker --version)"
echo "Compose: $(docker compose version --short 2>/dev/null || docker compose version)"

if tailscale status >/dev/null 2>&1; then
  echo "Tailscale IPv4: $(tailscale ip -4 2>/dev/null || true)"
else
  fail "tailscale is installed but not connected; run 'sudo tailscale up --ssh'"
fi

if [ -f docker-compose.yml ]; then
  compose_config="$(docker compose config)" || fail "docker compose config failed"
  if grep -qE '^[[:space:]]+ports:' <<<"$compose_config"; then
    fail "docker compose config contains published ports"
  fi
  echo "Compose ports: none published"
fi

if command -v ss >/dev/null 2>&1; then
  echo "Listening TCP sockets:"
  ss -ltnp 2>/dev/null | awk 'NR == 1 || /:22[[:space:]]/ || /tailscaled/ || /docker/'
fi

echo "Host check passed."
