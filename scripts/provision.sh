#!/bin/bash
# Native LXC provisioning for Astroneer Dedicated Server
# Based on https://github.com/birdhimself/astroneer-docker
# and https://github.com/birdhimself/container-base-images

set -euo pipefail

ASTRONEER_USER="${ASTRONEER_USER:-astroneer}"
ASTRONEER_HOME="${ASTRONEER_HOME:-/opt/astroneer}"
WINE_VERSION="${WINE_VERSION:-10.20}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo "Run as root: sudo $0"
    exit 1
fi

ARCH="$(dpkg --print-architecture)"
echo "Provisioning Astroneer LXC on ${ARCH}..."

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y \
    ca-certificates \
    curl \
    git \
    gnupg \
    gnutls-bin \
    python3-pip \
    python3-venv \
    tmux \
    wget \
    xz-utils

# Wine (same source as birdhimself/container-base-images)
if [[ "$ARCH" == "amd64" ]]; then
    mkdir -p /opt/wine
    wget -qO- "https://github.com/Kron4ek/Wine-Builds/releases/download/${WINE_VERSION}/wine-${WINE_VERSION}-staging-tkg-amd64-wow64.tar.xz" \
        | tar -xJ --strip-components=1 -C /opt/wine
    ln -sf /opt/wine/bin/wine /usr/local/bin/wine
elif [[ "$ARCH" == "arm64" ]]; then
    mkdir -p /opt/wine
    # ARM64 hosts run x86_64 Wine through Box64; use the amd64 Wine build.
    wget -qO- "https://github.com/Kron4ek/Wine-Builds/releases/download/${WINE_VERSION}/wine-${WINE_VERSION}-staging-tkg-amd64-wow64.tar.xz" \
        | tar -xJ --strip-components=1 -C /opt/wine
    ln -sf /opt/wine/bin/wine /usr/local/bin/wine
    bash "${REPO_ROOT}/scripts/install-box64.sh"
else
    echo "Unsupported architecture: ${ARCH} (need amd64 or arm64)"
    exit 1
fi

# Dedicated service user
if ! id "$ASTRONEER_USER" &>/dev/null; then
    useradd --system --home "$ASTRONEER_HOME" --shell /usr/sbin/nologin "$ASTRONEER_USER"
fi

mkdir -p "$ASTRONEER_HOME"
chown "$ASTRONEER_USER":"$ASTRONEER_USER" "$ASTRONEER_HOME"

# AstroTuxLauncher (birdhimself fork)
if [[ ! -d "${ASTRONEER_HOME}/.git" ]] && [[ ! -f "${ASTRONEER_HOME}/AstroTuxLauncher.py" ]]; then
    git clone https://github.com/birdhimself/AstroTuxLauncher.git "$ASTRONEER_HOME"
fi

chown -R "$ASTRONEER_USER":"$ASTRONEER_USER" "$ASTRONEER_HOME"

# Python dependencies
sudo -u "$ASTRONEER_USER" env ASTRONEER_HOME="$ASTRONEER_HOME" bash "${REPO_ROOT}/scripts/install.sh"

# Runtime scripts
install -m 0755 "${REPO_ROOT}/scripts/entrypoint.sh" /usr/local/bin/astroneer-entrypoint

# Environment file
mkdir -p /etc/astroneer
if [[ ! -f /etc/astroneer/astroneer.env ]]; then
    install -m 0644 "${REPO_ROOT}/config/astroneer.env.example" /etc/astroneer/astroneer.env
fi

# systemd unit
install -m 0644 "${REPO_ROOT}/systemd/astroneer.service" /etc/systemd/system/astroneer.service
systemctl daemon-reload

apt-get clean
rm -rf /var/lib/apt/lists/*

cat <<EOF

Provisioning complete.

Next steps:
  1. Bind-mount saves to: ${ASTRONEER_HOME}/AstroneerServer/Astro/Saved
  2. Edit /etc/astroneer/astroneer.env if needed
  3. systemctl enable --now astroneer
  4. journalctl -u astroneer -f

Attribution: https://github.com/birdhimself/astroneer-docker
EOF
