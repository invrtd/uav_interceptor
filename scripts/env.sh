#!/usr/bin/env bash
# Single source of truth for paths and Gazebo environment variables.
# Source this from other scripts:  source "$(dirname "$0")/env.sh"

# shellcheck disable=SC2034
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export REPO_ROOT

# Pinned submodules
export AP_ROOT="$REPO_ROOT/external/ardupilot"
export GZ_PLUGIN_ROOT="$REPO_ROOT/external/ardupilot_gazebo"
export GZ_PLUGIN_BUILD="$GZ_PLUGIN_ROOT/build"

# uv-managed virtualenv (created by `make setup` / `uv sync`)
if [[ -d "$REPO_ROOT/.venv/bin" ]]; then
    export PATH="$REPO_ROOT/.venv/bin:$PATH"
fi

# ArduPilot helper scripts (sim_vehicle.py, etc.)
if [[ -d "$AP_ROOT/Tools/autotest" ]]; then
    export PATH="$AP_ROOT/Tools/autotest:$PATH"
fi

# Gazebo plugin discovery. Only meaningful where Gazebo is installed locally.
if [[ -d "$GZ_PLUGIN_BUILD" ]]; then
    export GZ_SIM_SYSTEM_PLUGIN_PATH="$GZ_PLUGIN_BUILD:${GZ_SIM_SYSTEM_PLUGIN_PATH:-}"
fi
export GZ_SIM_RESOURCE_PATH="$REPO_ROOT/config/models:$GZ_PLUGIN_ROOT/models:$GZ_PLUGIN_ROOT/worlds:$REPO_ROOT/config/worlds:${GZ_SIM_RESOURCE_PATH:-}"
