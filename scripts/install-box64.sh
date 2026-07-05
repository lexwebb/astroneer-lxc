#!/bin/bash
# Adapted from https://github.com/birdhimself/container-base-images

set -euo pipefail

cat <<EOF > /etc/apt/sources.list.d/box64.sources
Types: deb
URIs: https://Pi-Apps-Coders.github.io/box64-debs/debian
Suites: ./
Signed-By: /etc/apt/keyrings/box64-archive-keyring.gpg
EOF

wget -qO- "https://pi-apps-coders.github.io/box64-debs/KEY.gpg" | gpg --dearmor -o /etc/apt/keyrings/box64-archive-keyring.gpg
apt-get update
apt-get install -y box64-generic-arm
