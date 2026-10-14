#!/usr/bin/env bash
# Bring up the interceptor sim: Gazebo world with TWO ArduPilot vehicles plus
# their SITL instances.
#
#   interceptor  -> SITL instance 0 (sysid 1), gimbaled camera, FDM 9002
#   target       -> SITL instance 1 (sysid 2), no camera,        FDM 9012
#
# The target streams telemetry to udp:127.0.0.1:14561 for the oracle
# (see fake_gs/oracle.py). Ports mirror interfaces/contract.py.
#
# Usage:
#   make sim-intercept              # interceptor console/map; target headless
#   CAMERA=1 make sim-intercept     # also stream the interceptor camera on :5600
#   HEADLESS=1 make sim-intercept   # Gazebo server only (no GUI)
set -euo pipefail
source "$(dirname "$0")/env.sh"

WORLD="${WORLD:-intercept.sdf}"
WORLD_NAME="${WORLD%.sdf}"
ENABLE_CAMERA="${CAMERA:-0}"
HEADLESS="${HEADLESS:-0}"

INTERCEPTOR_PARM="${PARM:-$REPO_ROOT/config/params/interceptor.parm}"
TARGET_ORACLE_PORT=14561

if ! command -v gz >/dev/null 2>&1; then
    echo "ERROR: Gazebo ('gz') not found on PATH. See docs/setup-linux.md." >&2
    exit 1
fi
if [[ ! -x "$AP_ROOT/build/sitl/bin/arducopter" ]]; then
    echo "ERROR: SITL not built. Run 'make sitl' first." >&2
    exit 1
fi

gz_args=(-v4 -r "$WORLD")
[[ "$HEADLESS" == "1" ]] && gz_args=(-s -r "$WORLD")

echo ">> launching Gazebo: gz sim ${gz_args[*]}"
gz sim "${gz_args[@]}" &
GZ_PID=$!

TARGET_PID=""
cleanup() {
    [[ -n "$TARGET_PID" ]] && kill "$TARGET_PID" 2>/dev/null || true
    kill "$GZ_PID" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

echo ">> waiting for Gazebo to come up..."
sleep 5

if [[ "$ENABLE_CAMERA" == "1" ]]; then
    CAM_TOPIC="/world/${WORLD_NAME}/model/iris_with_gimbal/model/gimbal/link/pitch_link/sensor/camera/image/enable_streaming"
    echo ">> enabling camera stream on $CAM_TOPIC (view on udp :5600)"
    gz topic -t "$CAM_TOPIC" -m gz.msgs.Boolean -p "data: 1" || \
        echo "   (camera enable failed - does $WORLD contain iris_with_gimbal?)" >&2
fi

# Target: no MAVProxy, telemetry out to the oracle feed port.
echo ">> launching TARGET SITL (instance 1, sysid 2)"
cd "$AP_ROOT"
sim_vehicle.py -v ArduCopter -f gazebo-iris -I1 --sysid 2 --model JSON \
    -N --no-mavproxy --out="udp:127.0.0.1:${TARGET_ORACLE_PORT}" &
TARGET_PID=$!

sleep 3

# Interceptor: the interactive vehicle (console + map).
echo ">> launching INTERCEPTOR SITL (instance 0, sysid 1) with console + map"
echo "   after it boots:  mode guided / arm throttle / takeoff 5 / mode follow"
sim_vehicle.py -v ArduCopter -f gazebo-iris -I0 --sysid 1 --model JSON \
    -N --add-param-file "$INTERCEPTOR_PARM" --console --map
