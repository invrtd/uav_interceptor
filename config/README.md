# config/

Team-owned configuration that is layered on top of the pinned upstream code.

## params/

ArduPilot parameter files (`.parm`) applied by `run-sim.sh` via
`sim_vehicle.py --add-param-file`. These are loaded *in addition to* the
frame defaults, so only the values you want to override need to be present.

| File | Purpose |
|------|---------|
| `gazebo-iris-gimbal.parm` | Iris + 3-axis gimbal: motor servo ranges, `MNT1_*` mount config, gimbal RC inputs. Copied from `external/ardupilot_gazebo/config/`. |
| `interceptor.parm` | Interceptor (`-I0`): enables Follow (`FOLL_ENABLE`) against the target sysid. Baseline for M2. |

Convention: name files `<frame>-<feature>.parm` and pass the path to the sim
with `PARM=config/params/<frame>-<feature>.parm make sim`.

## worlds/

Team `.sdf` world files or overrides. This directory is on
`GZ_SIM_RESOURCE_PATH`, so a world placed here can be launched by name:
`WORLD=my_world.sdf make sim`. Leave the upstream worlds in
`external/ardupilot_gazebo/worlds/` untouched.

| File | Purpose |
|------|---------|
| `intercept.sdf` | Two-vehicle interceptor world (interceptor + target). `make sim-intercept`. |

## models/

Team Gazebo models, also on `GZ_SIM_RESOURCE_PATH`. Models reference their
dependencies via `model://`, so a copy only needs its own `model.sdf` +
`model.config`.

| Model | Purpose |
|-------|---------|
| `target_iris/` | Target UAV: copy of upstream `iris_with_ardupilot` with `<fdm_port_in>` set to 9012 so SITL instance `-I1` drives it. Regenerate from upstream, then change only the port. |

