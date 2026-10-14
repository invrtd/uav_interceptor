#!/usr/bin/env bash
# Fetch the pinned submodules and create the uv-managed Python environment.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

echo ">> Initialising submodules (pinned revisions)"
git submodule update --init --recursive

echo ">> Creating Python environment with uv"
if ! command -v uv >/dev/null 2>&1; then
    echo "ERROR: 'uv' not found. Install it: https://docs.astral.sh/uv/getting-started/installation/" >&2
    exit 1
fi
uv sync

echo
echo "Setup complete. Next:"
echo "  make sitl     # build the ArduPilot SITL binary"
echo "  make plugin   # build the Gazebo plugin (requires Gazebo installed locally)"
echo "  make doctor   # check your environment"
