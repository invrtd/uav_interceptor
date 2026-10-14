# Troubleshooting

Check `~/.gz/sim/log/<timestamp>/server_console.log` for the latest Gazebo
errors. The entries below are real failures seen during initial setup.

## Gazebo

**`Unable to find uri[model://runway]` / `model://iris_with_gimbal`**
The model path is not on `GZ_SIM_RESOURCE_PATH`. Launch through the scripts
(they source `scripts/env.sh`) rather than calling `gz sim` by hand. If you must
run `gz sim` directly:

```bash
source scripts/env.sh
gz sim -v4 -r iris_runway.sdf
```

Also make sure the submodule is checked out: `git submodule update --init external/ardupilot_gazebo`.

**`Another world of the same name is running`**
A previous `gz sim` is still alive. `pkill -f "gz sim"` (or
`pkill -f "ruby.*gz"`), then retry. `make sim` cleans up its own Gazebo on exit,
but a crashed run may leave one behind.

**`DART: Cone/Ellipsoid is not a supported collision geometry primitive`**
Benign warning from the physics backend; not an error.

**GUI opens but everything is black / camera is extremely slow**
You are on software rendering (`llvmpipe`). Confirm with `glxinfo -B`; install
the proprietary GPU driver. `make doctor` flags this.

## Camera

**`GstCameraPlugin: failed to create GStreamer elements`**
Missing GStreamer plugins used by the encode pipeline (`rtph264pay`,
`udpsink`, `x264enc`/`openh264enc`). Install:

```bash
sudo apt install gstreamer1.0-plugins-bad gstreamer1.0-plugins-good \
  gstreamer1.0-libav gstreamer1.0-gl
```

Then `gst-inspect-1.0 rtph264pay` should succeed.

**No video on :5600**
- Did you enable streaming? `CAMERA=1 make sim` does it; otherwise publish the
  `.../image/enable_streaming` boolean (see `docs/sim-bringup.md`).
- Is the world using `iris_with_gimbal`? The camera topic only exists for that
  model.
- Is `udp :5600` in use by another process? `make doctor` checks.

## SITL / build

**`make sitl` fails to configure**
Ensure submodules are present (`make setup`) and `uv` is installed. Never run
`waf` with `sudo`.

**SITL can't find a Python module**
Run tools through the managed env (`uv run ...` or `make ...`). Do not use a
system Python; `empy` must be `3.3.4` (already pinned).

**SITL connects but the vehicle doesn't move in Gazebo**
The SITL model must be `JSON` and the frame must contain `gazebo-` (e.g.
`-f gazebo-iris --model JSON`). Check the world's `ArduPilotPlugin` UDP
address/port matches SITL's.
