#!/bin/bash
# Remove a provision.sh install (service, files, dedicated user).
# Does not uninstall apt packages or revert WSL/Windows host settings.

set -euo pipefail

ASTRONEER_USER="${ASTRONEER_USER:-astroneer}"
ASTRONEER_HOME="${ASTRONEER_HOME:-/opt/astroneer}"
CONFIRM="${CONFIRM:-}"

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo "Run as root: sudo $0"
    exit 1
fi

if [[ ! "$CONFIRM" =~ ^([Yy]|[Yy][Ee][Ss])$ ]]; then
    cat <<EOF
This removes the Astroneer dedicated server install:

  - systemd service: astronee
  - ${ASTRONEER_HOME}
  - /opt/wine and /usr/local/bin/wine
  - /etc/astronee
  - user: ${ASTRONEER_USER}

Saves under ${ASTRONEER_HOME}/AstroneerServer/Astro/Saved are deleted unless
you moved or symlinked them elsewhere.

Re-run with CONFIRM=yes to proceed:

  sudo CONFIRM=yes $0
EOF
    exit 0
fi

echo "Stopping and disabling astroneer service..."
if systemctl is-active --quiet astroneer 2>/dev/null; then
    systemctl stop astronee
fi
if systemctl is-enabled --quiet astroneer 2>/dev/null; then
    systemctl disable astronee
fi

echo "Removing systemd unit and entrypoint..."
rm -f /etc/systemd/system/astroneer.service
rm -f /usr/local/bin/astroneer-entrypoint
systemctl daemon-reload

echo "Removing install tree and config..."
rm -rf "$ASTRONEER_HOME" /opt/wine /etc/astronee
rm -f /usr/local/bin/wine

if id "$ASTRONEER_USER" &>/dev/null; then
    echo "Removing user ${ASTRONEER_USER}..."
    userdel "$ASTRONEER_USER"
fi

ARCH="$(dpkg --print-architecture 2>/dev/null || true)"
if [[ "$ARCH" == "arm64" ]]; then
    rm -f /etc/apt/sources.list.d/box64.sources /etc/apt/keyrings/box64-archive-keyring.gpg
    if dpkg -l box64-generic-arm &>/dev/null; then
        apt-get remove -y box64-generic-arm || true
    fi
fi

cat <<EOF

Teardown complete.

Host settings this script does not touch:
  - apt packages installed during provision (git, tmux, python3-venv, ...)
  - Windows .wslconfig mirrored networking
  - Windows firewall rules or client Engine.ini encryption override

EOF
