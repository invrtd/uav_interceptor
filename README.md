# ardupilot-gazebo-sim

Team dev environment for running **ArduPilot SITL** against **Gazebo** with the
official [`ardupilot_gazebo`](https://github.com/ArduPilot/ardupilot_gazebo)
plugin, and the home of the **UAV interceptor** project built on top of it.

Both upstream projects are pinned as git submodules, and the Python tooling is
managed by [uv](https://docs.astral.sh/uv/) so every teammate gets an identical
environment with `make setup`.

> **The interceptor project.** A pursuit UAV whose FPV camera feeds a ground
> station that detects a target; the goal is *ranging + pursue to contact*. The
> ground station is owned by **another subteam** — this repo talks to it only
> over the MAVLink contract in [`docs/interface.md`](docs/interface.md). Until
> that subteam's detector exists, [`fake_gs/`](fake_gs/) (the *oracle*) feeds
> the target's simulated state instead. See [`docs/architecture.md`](docs/architecture.md)
> and [`docs/roadmap.md`](docs/roadmap.md).

## Requirements

- **Linux** (native) or **Windows + WSL2** — the build/run scripts are bash and
  work in both. macOS can run SITL but the Gazebo plugin path is untested here.
- [`uv`](https://docs.astral.sh/uv/getting-started/installation/) (single binary; installs Python too).
- `git`, `cmake`, a C++ toolchain (`build-essential`).
- **Gazebo is installed per-person** (not managed by this repo). See
  [`docs/setup-linux.md`](docs/setup-linux.md). The plugin needs the Gazebo
  Harmonic dev libraries.

## Quickstart

```bash
git clone <this-repo> ardupilot-gazebo-sim
cd ardupilot-gazebo-sim
make setup     # submodules + uv environment
make sitl      # build SITL   (waf configure --board sitl && waf copter)
make plugin    # build the Gazebo plugin (needs Gazebo installed)
make sim       # launch Gazebo + SITL + MAVProxy

# Interceptor sim (two vehicles):
make sim-intercept   # terminal 1: Gazebo + interceptor + target
make fake-gs         # terminal 2: the oracle ground station
```

Check your machine at any time:

```bash
make doctor
```

## `make sim` flags

| Flag | Effect |
|------|--------|
| `CAMERA=1` | Start streaming the gimbal camera; view on linux `udp :5600` (QGC / `gst-launch`). |
| `HEADLESS=1` | Run the Gazebo **server only** (no GUI) — for WSL/CI. |
| `WORLD=` `VEHICLE=` `FRAME=` | Override the sim defaults (see `scripts/run-sim.sh`). |
| `PARM=` | Override the parameter file (default `config/params/gazebo-iris-gimbal.parm`). |

Example:

```bash
WORLD=zephyr_runway.sdf VEHICLE=ArduPlane FRAME=gazebo-zephyr make sim
CAMERA=1 make sim
```

Then in the MAVProxy console:

```
STABILIZE> mode guided
GUIDED> arm throttle
GUIDED> takeoff 5
```

## Repository layout

```
Makefile            thin front-end; all logic lives in scripts/
pyproject.toml      Python deps (uv.lock pins them)
scripts/            setup / build / run / intercept / doctor logic
interfaces/         MAVLink contract shared with the ground-station subteam
fake_gs/            oracle stand-in for the ground station (throwaway)
guidance/           pursuit / ranging math
onboard/            optional ArduPilot Lua scripts (onboard guidance)
config/params/      team .parm files
config/worlds/      team .sdf worlds (on GZ_SIM_RESOURCE_PATH)
config/models/      team Gazebo models (on GZ_SIM_RESOURCE_PATH)
docs/               architecture, interface, roadmap + platform docs
external/           pinned submodules: ardupilot, ardupilot_gazebo
```

## Project docs

- [`docs/architecture.md`](docs/architecture.md) — ownership, the loop, why MAVLink decouples the subteams.
- [`docs/interface.md`](docs/interface.md) — the ground-station ↔ interceptor contract.
- [`docs/roadmap.md`](docs/roadmap.md) — M0–M5 milestones.

## Platform support

| Platform | SITL | Gazebo + plugin | Virtual camera |
|----------|------|-----------------|----------------|
| Linux + NVIDIA | works | works (reference) | works via ogre2 |
| Windows + WSL2 | works | GUI = best-effort under WSLg | **not yet validated** — see `docs/setup-windows-wsl.md` |
| macOS | works | plugin build untested | untested |

The WSL/WSLg GUI + camera path is a known open item; the Windows side is
intentionally deferred. Use `HEADLESS=1` on WSL until it is validated.

## Migrating from the old layout

This repo replaces the loose `~/ardupilot` and `~/gz_ws/src/ardupilot_gazebo`
checkouts. Those are left in place. To switch:

1. `make setup && make sitl && make plugin`
2. Run `make sim` from this repo instead of hand-exporting `GZ_SIM_*` and
   launching `gz sim`/`sim_vehicle.py` manually.

Nothing in the old directories is modified.

## License

Submodules retain their own licenses (ArduPilot: GPLv3; ardupilot_gazebo:
GPLv3). See `external/*/COPYING*`.
