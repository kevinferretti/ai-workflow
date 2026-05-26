#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -eq 0 ]; then
  echo "ERROR: run this script as the normal VM user, not root. It will use sudo when needed." >&2
  exit 1
fi

if [ ! -f /etc/os-release ]; then
  echo "ERROR: /etc/os-release not found; this bootstrap currently supports Ubuntu only." >&2
  exit 1
fi

. /etc/os-release

if [ "${ID:-}" != "ubuntu" ]; then
  echo "ERROR: unsupported OS '${ID:-unknown}'. This bootstrap currently supports Ubuntu only." >&2
  exit 1
fi

sudo apt-get update
sudo apt-get install -y --no-install-recommends ca-certificates curl git gnupg lsb-release openssh-server

if ! command -v docker >/dev/null 2>&1; then
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt-get update
  sudo apt-get install -y --no-install-recommends docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

if ! command -v tailscale >/dev/null 2>&1; then
  curl -fsSL "https://pkgs.tailscale.com/stable/ubuntu/${VERSION_CODENAME}.noarmor.gpg" \
    | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
  curl -fsSL "https://pkgs.tailscale.com/stable/ubuntu/${VERSION_CODENAME}.tailscale-keyring.list" \
    | sudo tee /etc/apt/sources.list.d/tailscale.list >/dev/null
  sudo apt-get update
  sudo apt-get install -y --no-install-recommends tailscale
fi

sudo systemctl enable --now ssh
sudo systemctl enable --now docker
sudo usermod -aG docker "${USER}"

cat <<'MESSAGE'
Host bootstrap complete.

Next steps:
1. Log out and back in so Docker group membership applies.
2. Join the tailnet:
   sudo tailscale up --ssh
3. Clone this repo onto the VM.
4. Run:
   bash scripts/check-host.sh
   bash scripts/start-workspace.sh
MESSAGE
