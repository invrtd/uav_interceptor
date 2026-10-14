# Roadmap

Sim-first. The ground station is built by another subteam; until it exists we
use the oracle (`fake_gs/`) so the air side can progress independently.

| Milestone | Deliverable | Oracle? | Done when |
|-----------|-------------|:-------:|-----------|
| **M0** | SITL + Gazebo bring-up (`make sim`) | no | one vehicle flies in `iris_runway.sdf` |
| **M1** | Two-vehicle world + oracle (`make sim-intercept`, `make fake-gs`) | yes | target flies; oracle republishes its state to the interceptor over MAVLink |
| **M2** | Pursuit closes the loop | yes (or none) | interceptor autonomously pursues the simulated target |
| **M3** | Ranging + pursue-to-contact | yes | "interception" criterion (range → contact) demonstrated in sim |
| **M4** | Swap oracle → real ground station | no | detector publishes the same messages over BoxPro+ WiFi video |
| **M5** | Bench / HITL | real | loop closes with hardware in the loop |

## M1 — Two-vehicle world + oracle  ← *current*

- `config/worlds/intercept.sdf`: interceptor (`iris_with_gimbal`, FDM 9002) +
  target (`target_iris`, FDM 9003).
- `scripts/run-intercept.sh`: launch Gazebo + two SITL instances with distinct
  sysids/ports.
- `fake_gs/oracle.py`: listen to target telemetry, emit `FOLLOW_TARGET` to the
  interceptor — identical to the future ground station's output.
- `make sim-intercept`, `make fake-gs`.
- Validate on the Linux + NVIDIA reference machine (the `gz`-in-distrobox setup
  means `make` must run inside the container).

## M2 — Pursuit

- `guidance/`: pursuit law (range + closing velocity from the track).
- Fly the interceptor in `FOLLOW` (uses `FOLLOW_TARGET`) as the baseline before
  a custom law.

## M3 — Ranging + contact

- Define "contact" from the range estimate; log time-to-contact.
- Tune the law; measure the sense→command latency budget.

## M4 — Real ground station

- Video source switches from sim/UDP to BoxPro+ WiFi stream (`groundstation`
  repo).
- Detector + ranging replace the oracle; contract unchanged.

## M5 — Hardware

- Bench FC + video link; then HITL.
