#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

warn() {
  echo "WARN: $*" >&2
}

if [ "$(id -u)" -eq 0 ]; then
  fail "run this script as the normal VM user, not root. It will use sudo when needed."
fi

[ -f /etc/os-release ] || fail "/etc/os-release not found; this bootstrap currently supports Ubuntu only."

. /etc/os-release

if [ "${ID:-}" != "ubuntu" ]; then
  fail "unsupported OS '${ID:-unknown}'. This bootstrap currently supports Ubuntu only."
fi

case "${VERSION_ID:-}" in
  24.04)
    ;;
  *)
    warn "expected Ubuntu 24.04 LTS; found VERSION_ID=${VERSION_ID:-unknown}"
    ;;
esac

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "${repo_root}"

if [ -f .env ]; then
  set -a
  # shellcheck disable=SC1091
  . ./.env
  set +a
fi

workspace_user="${WORKSPACE_USER:-codex}"
codex_npm_version="${CODEX_NPM_VERSION:-0.132.0}"
glab_version="${GLAB_VERSION:-1.99.0}"
node_major="${NODE_MAJOR:-22}"
tz="${TZ:-UTC}"

export DEBIAN_FRONTEND=noninteractive

sudo apt-get update
sudo apt-get install -y --no-install-recommends \
  acl \
  bash-completion \
  bubblewrap \
  build-essential \
  ca-certificates \
  curl \
  dnsutils \
  fd-find \
  fzf \
  gh \
  git \
  git-lfs \
  gnupg \
  iproute2 \
  jq \
  less \
  locales \
  lsb-release \
  man-db \
  nano \
  openssh-client \
  openssh-server \
  pkg-config \
  python3 \
  python3-pip \
  python3-venv \
  ripgrep \
  rsync \
  sudo \
  unzip \
  vim

sudo locale-gen en_US.UTF-8
sudo ln -sf /usr/bin/fdfind /usr/local/bin/fd
sudo git lfs install --system

installed_node_major=""
if command -v node >/dev/null 2>&1; then
  installed_node_major="$(node --version | sed -E 's/^v([0-9]+).*/\1/')"
fi

if [ "${installed_node_major}" != "${node_major}" ]; then
  sudo install -m 0755 -d /etc/apt/keyrings
  tmp_key="$(mktemp)"
  curl -fsSL "https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key" \
    | gpg --dearmor >"${tmp_key}"
  sudo install -m 0644 "${tmp_key}" /etc/apt/keyrings/nodesource.gpg
  rm -f "${tmp_key}"
  echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${node_major}.x nodistro main" \
    | sudo tee /etc/apt/sources.list.d/nodesource.list >/dev/null
  sudo apt-get update
  sudo apt-get install -y --no-install-recommends nodejs
fi

if ! command -v tailscale >/dev/null 2>&1; then
  curl -fsSL "https://pkgs.tailscale.com/stable/ubuntu/${VERSION_CODENAME}.noarmor.gpg" \
    | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
  curl -fsSL "https://pkgs.tailscale.com/stable/ubuntu/${VERSION_CODENAME}.tailscale-keyring.list" \
    | sudo tee /etc/apt/sources.list.d/tailscale.list >/dev/null
  sudo apt-get update
  sudo apt-get install -y --no-install-recommends tailscale
fi

install_glab=1
if command -v glab >/dev/null 2>&1 && glab --version 2>/dev/null | grep -F "glab version ${glab_version}" >/dev/null; then
  install_glab=0
fi

if [ "${install_glab}" -eq 1 ]; then
  [ "$(dpkg --print-architecture)" = "amd64" ] || fail "glab bootstrap currently supports amd64 only"
  tmp_deb="$(mktemp --suffix=.deb)"
  curl -fsSL -o "${tmp_deb}" "https://gitlab.com/api/v4/projects/gitlab-org%2Fcli/packages/generic/glab/${glab_version}/glab_${glab_version}_linux_amd64.deb"
  sudo apt-get install -y --no-install-recommends "${tmp_deb}"
  rm -f "${tmp_deb}"
fi

if ! command -v codex >/dev/null 2>&1 || ! codex --version 2>/dev/null | grep -F "${codex_npm_version}" >/dev/null; then
  sudo npm install -g "@openai/codex@${codex_npm_version}"
  sudo npm cache clean --force
fi

if ! id -u "${workspace_user}" >/dev/null 2>&1; then
  sudo useradd --create-home --shell /bin/bash "${workspace_user}"
fi

sudo usermod --shell /bin/bash "${workspace_user}"
sudo usermod -aG sudo "${workspace_user}"
printf '%s ALL=(ALL) NOPASSWD:ALL\n' "${workspace_user}" \
  | sudo tee "/etc/sudoers.d/${workspace_user}" >/dev/null
sudo chmod 0440 "/etc/sudoers.d/${workspace_user}"

if [ -f "${HOME}/.ssh/authorized_keys" ]; then
  workspace_home="$(getent passwd "${workspace_user}" | cut -d: -f6)"
  sudo install -d -m 0700 -o "${workspace_user}" -g "${workspace_user}" "${workspace_home}/.ssh"
  sudo install -m 0600 -o "${workspace_user}" -g "${workspace_user}" "${HOME}/.ssh/authorized_keys" "${workspace_home}/.ssh/authorized_keys"
fi

workspace_home="$(getent passwd "${workspace_user}" | cut -d: -f6)"
workspace_repo="${workspace_home}/ai-workflow"
if [ ! -e "${workspace_repo}" ]; then
  sudo install -d -m 0755 -o "${workspace_user}" -g "${workspace_user}" "${workspace_repo}"
  sudo rsync -a \
    --exclude '.env' \
    --exclude '.state' \
    --exclude 'workspace' \
    --exclude 'backups' \
    "${repo_root}/" "${workspace_repo}/"
  sudo chown -R "${workspace_user}:${workspace_user}" "${workspace_repo}"
elif [ ! -d "${workspace_repo}/.git" ]; then
  warn "not seeding ${workspace_repo}; path already exists and is not a git checkout"
fi

sudo timedatectl set-timezone "${tz}" 2>/dev/null || warn "could not set timezone to ${tz}"
sudo systemctl enable --now ssh
sudo systemctl enable --now tailscaled 2>/dev/null || true

cat <<MESSAGE
Host bootstrap complete.

Next steps:
1. Join the tailnet:
   sudo tailscale up --ssh
2. Connect as the workspace user over Tailscale:
   ssh ${workspace_user}@<TAILSCALE_IP>
3. Prepare the seeded workspace repo:
   cd ~/ai-workflow
   cp .env.example .env
   bash scripts/start-workspace.sh
   bash scripts/check-host.sh
   bash scripts/check-workspace.sh
MESSAGE
