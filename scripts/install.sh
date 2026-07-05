#!/bin/bash
# Adapted from https://github.com/birdhimself/astroneer-docker

set -euo pipefail

ASTRONEER_HOME="${ASTRONEER_HOME:-/opt/astroneer}"

cd "$ASTRONEER_HOME"

python3 -m venv ./venv
source ./venv/bin/activate

pip install -r requirements.txt
