# Linux setup

This repo manages the ArduPilot + Python side. **Gazebo itself is installed
per-person** (not by `make setup`), because it is a system package that pulls in
GPU/driver dependencies.

## 1. Gazebo (Harmonic)

```bash
sudo apt update
sudo apt install -y curl gnupg lsb-release

sudo curl https://packages.osrfoundation.org/gazebo.gpg \
  --output /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] \
https://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/gazebo-stable.list > /dev/null
sudo apt update
sudo apt install -y gz-harmonic
```

Verify: `gz sim -v4 -r shapes.sdf` opens the GUI, or `gz sim --versions`.

> The pinned plugin targets **Gazebo Harmonic** (`gz-sim8`). Other releases
> (Garden/Ionic) may work but are untested here.

## 2. Plugin build dependencies

```bash
sudo apt install -y \
  libgz-sim8-dev rapidjson-dev \
  libopencv-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
  gstreamer1.0-plugins-bad gstreamer1.0-libav gstreamer1.0-gl
```

## 3. This repo

```bash
make setup     # submodules + uv environment (installs uv-managed Python)
make sitl      # ArduPilot SITL binary
make plugin    # cmake build of libArduPilotPlugin.so etc.
make doctor    # confirm everything is detected
make sim
```

## 4. GPU notes (NVIDIA)

- The camera sensor and GUI use the **ogre2** renderer, which needs a real
  GL/Vulkan context. If `make doctor` reports **llvmpipe**, you are on software
  rendering and the camera will be very slow — install the proprietary NVIDIA
  driver and re-check.
- gazebo/models/worlds are resolved via `GZ_SIM_RESOURCE_PATH`, which
  `scripts/env.sh` sets for you. If you launch `gz sim` outside these scripts,
  source `scripts/env.sh` first.

## 5. Uninstall-ish

- Builds: `make clean`.
- Python env: `rm -rf .venv`.
- Submodule checkouts: `git submodule deinit -f external/ardupilot external/ardupilot_gazebo`.
