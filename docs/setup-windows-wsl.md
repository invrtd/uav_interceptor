# Windows + WSL2 setup (initial, GUI deferred)

The bash scripts work unmodified under WSL2, so the **ArduPilot/SITL/Python
side** is supported today. The **Gazebo GUI and virtual camera** under WSLg are
**not yet validated** — treat that as the open item.

## What works now

Run inside a WSL2 Ubuntu distro:

```bash
make setup
make sitl
make doctor          # will report gz missing until you install it in WSL
make sim HEADLESS=1  # Gazebo server only (no GUI)
```

Use **Mission Planner / QGroundControl running natively on Windows** as the
GCS: they connect to SITL over MAVLink UDP. WSL2 usually forwards `localhost`,
but UDP forwarding can be flaky — if the GCS does not see the vehicle, forward
the port explicitly:

```powershell
# In Windows PowerShell (Admin), per boot:
netsh interface portproxy add v4tov4 listenport=14550 listenaddress=0.0.0.0 `
  connectport=14550 connectaddress=(wsl hostname -I).Trim()
```

## Installing Gazebo in WSL

```bash
# inside WSL, follow docs/setup-linux.md steps 1-2, then:
export GZ_VERSION=harmonic
make plugin
```

## OPEN ITEM: validate the WSLg GUI + camera

Before we claim camera support on Windows, one person must run the world under
WSLg and report back:

1. `sudo apt install mesa-utils && glxinfo -B`
   - Is the renderer a real GPU or `llvmpipe` (software)?
2. `gz sim -v4 -r iris_runway.sdf` (with a display) — does the GUI open?
3. `CAMERA=1 make sim` — do frames arrive? Test with:
   ```bash
   gst-launch-1.0 -v udpsrc port=5600 caps='application/x-rtp, media=(string)video, \
     clock-rate=(int)90000, encoding-name=(string)H264' ! rtph264depay ! avdec_h264 \
     ! videoconvert ! autovideosink sync=false
   ```
4. Check `~/.gz/sim/log/<latest>/server_console.log` for render errors.

Record the result here (renderer string + whether the camera worked). If it
falls back to `llvmpipe`, the camera will be too slow — the fallbacks are:
SITL-only on Windows, or a teammate's Linux+NVIDIA machine on the same LAN.

## Known WSL caveats

- WSLg GPU acceleration is provided via a paravirtualized driver; `ogre2`
  support is inconsistent. Expect software rendering unless proven otherwise.
- GUI apps need `QT_QPA_PLATFORM=xcb` in some setups.
