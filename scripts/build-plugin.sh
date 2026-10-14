#!/usr/bin/env bash
# Build the ArduPilot Gazebo plugin (libArduPilotPlugin.so + friends).
# Requires Gazebo (Harmonic) dev libraries installed on this machine.
set -euo pipefail
source "$(dirname "$0")/env.sh"

if ! command -v gz >/dev/null 2>&1; then
    echo "ERROR: Gazebo ('gz') not found on PATH." >&2
    echo "Install Gazebo Harmonic first, then re-run 'make plugin'." >&2
    echo "See docs/setup-linux.md." >&2
    exit 1
fi

echo ">> configuring $GZ_PLUGIN_ROOT"
cmake -S "$GZ_PLUGIN_ROOT" -B "$GZ_PLUGIN_BUILD" -DCMAKE_BUILD_TYPE=RelWithDebInfo
echo ">> building plugin"
cmake --build "$GZ_PLUGIN_BUILD" -j"$(nproc)"

echo
echo "Plugins built in: $GZ_PLUGIN_BUILD"
ls "$GZ_PLUGIN_BUILD"/*.so 2>/dev/null || true
