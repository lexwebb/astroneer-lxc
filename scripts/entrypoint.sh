#!/bin/bash
# Adapted from https://github.com/birdhimself/astroneer-docker

set -euo pipefail

ASTRONEER_HOME="${ASTRONEER_HOME:-/opt/astroneer}"

cd "$ASTRONEER_HOME"

if [[ "${FORCE_CHOWN:-false}" =~ ^([Tt][Rr][Uu][Ee]|1|[Yy][Ee][Ss])$ ]]; then
    echo "Force chowning ${ASTRONEER_HOME} folder."
    chown -R "$(id -u)":"$(id -g)" "$ASTRONEER_HOME"
    echo "Done chowning."
fi

source ./venv/bin/activate

if [[ "${CREATE_LAUNCHER_CONFIG:-true}" =~ ^(true|1|yes)$ ]] || [[ ! -f "${ASTRONEER_HOME}/launcher.toml" ]]; then
    python3 AstroTuxLauncher.py genconfig
fi

# Use a temporary file to edit launcher.toml because bind mounts can break sed -i.
TEMPFILE=$(mktemp)
cp launcher.toml "$TEMPFILE"

shopt -s nocasematch

sed -i 's/OverrideWinePath.*/OverrideWinePath = "\/opt\/wine\/bin\/wine"/' "$TEMPFILE"

if [ -f /usr/local/bin/box64 ]; then
    sed -i 's/WrapperPath.*/WrapperPath = "\/usr\/local\/bin\/box64"/' "$TEMPFILE"
fi

if [[ "${DISABLE_ENCRYPTION:-false}" =~ ^(true|1|yes)$ ]]; then
    echo "Encryption will be disabled because DISABLE_ENCRYPTION is set."
    echo "See https://github.com/birdhimself/astroneer-docker#configuring-clients-if-encryption-is-disabled"
    sed -i 's/^DisableEncryption.*/DisableEncryption = true/' "$TEMPFILE"
else
    echo "Encryption will be enabled."
    sed -i 's/^DisableEncryption.*/DisableEncryption = false/' "$TEMPFILE"
fi

if [[ "${DEBUG:-false}" =~ ^(true|1|yes)$ ]]; then
    export BOX64_LOG=1
    sed -i 's/^LogDebugMessages.*/LogDebugMessages = true/' "$TEMPFILE"
else
    export BOX64_LOG=0
    sed -i 's/^LogDebugMessages.*/LogDebugMessages = false/' "$TEMPFILE"
fi

shopt -u nocasematch

cp "$TEMPFILE" launcher.toml
rm -f "$TEMPFILE"

python3 AstroTuxLauncher.py install
python3 AstroTuxLauncher.py start
