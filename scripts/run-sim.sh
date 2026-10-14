#!/usr/bin/env bash
# Bring up a Gazebo world + ArduPilot SITL + MAVProxy console.
#
# Usage:
#   make sim                 # iris_runway + ArduCopter + mavproxy console/map
#   CAMERA=1 make sim        # also start streaming the gimbal camera on :5600
#   HEADLESS=1 make sim      # run the Gazebo server only (no GUI) for WSL/CI
#   WORLD=zephyr_runway.sdf VEHICLE=ArduPlane FRAME=gazebo-zephyr make sim
set -euo pipefail
source "$(dirname "$0")/env.sh"

WORLD="${WORLD:-iris_runway.sdf}"
VEHICLE="${VEHICLE:-ArduCopter}"
FRAME="${FRAME:-gazebo-iris}"
PARM="${PARM:-$REPO_ROOT/config/params/gazebo-iris-gimbal.parm}"
ENABLE_CAMERA="${CAMERA:-0}"
HEADLESS="${HEADLESS:-0}"
WORLD_NAME="${WORLD%.sdf}"

if ! command -v gz >/dev/null 2>&1; then
    echo "ERROR: Gazebo ('gz') not found on PATH. See docs/setup-linux.md." >&2
    exit 1
fi
if [[ ! -x "$AP_ROOT/build/sitl/bin/arducopter" ]]; then
    echo "ERROR: SITL not built. Run 'make sitl' first." >&2
    exit 1
fi

gz_args=(-v4 -r "$WORLD")
if [[ "$HEADLESS" == "1" ]]; then
    gz_args=(-s -r "$WORLD")
fi

echo ">> launching Gazebo: gz sim ${gz_args[*]}"
gz sim "${gz_args[@]}" &
GZ_PID=$!
cleanup() { kill "$GZ_PID" 2>/dev/null || true; }
trap cleanup EXIT INT TERM

if [[ "$ENABLE_CAMERA" == "1" ]]; then
    CAM_TOPIC="/world/${WORLD_NAME}/model/iris_with_gimbal/model/gimbal/link/pitch_link/sensor/camera/image/enable_streaming"
    echo ">> enabling camera stream on $CAM_TOPIC (view on udp :5600)"
    sleep 5
    gz topic -t "$CAM_TOPIC" -m gz.msgs.Boolean -p "data: 1" || \
        echo "   (camera enable failed - does $WORLD contain iris_with_gimbal?)" >&2
fi

echo ">> launching SITL: sim_vehicle.py -v $VEHICLE -f $FRAME --model JSON"
cd "$AP_ROOT"
sim_vehicle.py -v "$VEHICLE" -f "$FRAME" --model JSON \
    --add-param-file "$PARM" --console --map
