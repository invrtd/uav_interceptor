# How the simulation is wired

## Processes

`make sim` starts two processes that talk to each other:

1. **Gazebo** (`gz sim -r <world>`) — physics, sensors, rendering.
2. **ArduPilot SITL** (`sim_vehicle.py -v ArduCopter -f gazebo-iris --model JSON`)
   — the autopilot, plus MAVProxy as the console/GCS.

```
        MAVLink (udp)                JSON FDM (udp)
GCS  ◀───────────────▶  SITL ◀──────────────────────▶  Gazebo
(QGC/MP/MAVProxy)                                     (ArduPilotPlugin)
                                                              │
                                                   ogre2 render (camera)
                                                              │
                                                   GstCameraPlugin
                                                              │
                                            RTP/H.264 ── udp :5600 ──▶ QGC / gst-launch
```

## Key ports / topics

| What | Where |
|------|-------|
| MAVLink | `udp :14550` (MAVProxy/QGC), plus `:14551` etc. |
| SITL ↔ Gazebo JSON | UDP, controlled by the world's `ArduPilotPlugin` (`<fdm_addr>`/`<fdm_port_in>`) and `--model JSON` |
| Camera stream | RTP/H.264 `udp :5600` |
| Camera (raw) topic | `/world/<world>/model/iris_with_gimbal/model/gimbal/link/pitch_link/sensor/camera/image` |
| Enable camera streaming | publish `gz.msgs.Boolean {data: 1}` to `.../image/enable_streaming` |

## Lockstepping

The world uses `type="ignore"` physics with a 1 ms step. ArduPilot and Gazebo
advance in lockstep via the JSON interface, so `SIM_SPEEDUP` and GDB work as
documented upstream.

## The virtual camera

The camera is a Gazebo `<sensor type="camera">` rendered by
`gz-sim-sensors-system` (`render_engine: ogre2`), then encoded by
`libGstCameraPlugin.so` into H.264 over UDP. `CAMERA=1 make sim` fires the
`enable_streaming` topic for you.

View it:

```bash
gst-launch-1.0 -v udpsrc port=5600 caps='application/x-rtp, media=(string)video, \
  clock-rate=(int)90000, encoding-name=(string)H264' ! rtph264depay ! avdec_h264 \
  ! videoconvert ! autovideosink sync=false
```

Or: **QGC → Application Settings → Video Settings → UDP h.264, port 5600.**

Set `<use_cuda>true</use_cuda>` in the camera plugin block (in the gimbal model
`.sdf`) to use `nvh264enc` on an NVIDIA render host.

### Open decision: H.264 vs raw frames

The current path gives an **encoded H.264 stream** (good for a human watching).
If the project needs **raw image frames in code** (vision/payload), tap the gz
image topic with a `gz.transport` client instead — that client must run on the
same machine as Gazebo. Not yet decided.

## Worlds available (from the pinned plugin)

`iris_runway.sdf` (default), `iris_warehouse.sdf`, `gimbal.sdf`,
`zephyr_runway.sdf`, `zephyr_parachute.sdf`. Select with `WORLD=... make sim`.
