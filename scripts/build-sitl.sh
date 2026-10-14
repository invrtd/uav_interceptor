#!/usr/bin/env bash
# Build the ArduPilot SITL binary (arducopter) in the pinned submodule.
set -euo pipefail
source "$(dirname "$0")/env.sh"

if [[ ! -x "$AP_ROOT/waf" ]]; then
    echo "ERROR: ArduPilot submodule not initialised. Run 'make setup'." >&2
    exit 1
fi

cd "$AP_ROOT"
echo ">> waf configure --board sitl"
./waf configure --board sitl
echo ">> waf copter"
./waf copter

echo
echo "SITL binary: $AP_ROOT/build/sitl/bin/arducopter"
