# fake_gs/ — the oracle (THROWAWAY)

This is the **stand-in for the ground-station subteam's detector**, used only
while that subteam has not built the real pipeline. It replaces the
video → detection → tracking → ranging chain with the target's *true* state,
read straight from its MAVLink telemetry, then emits the exact message the real
ground station will emit (see `../docs/interface.md`).

```
target SITL ──GLOBAL_POSITION_INT──▶ oracle ──FOLLOW_TARGET──▶ interceptor SITL
   (udp :14561)                                 (tcp :5760)
```

## Rules

- **Keep it tiny and obviously temporary.** No detection logic here, ever.
- **Delete it** the moment the real ground station publishes the same messages.
- It must speak only the contract in `../interfaces/contract.py` — never reach
  into `guidance/` or the sim internals.

## Run

```bash
make sim-intercept      # terminal 1: Gazebo + both SITL instances
make fake-gs            # terminal 2: the oracle
```
