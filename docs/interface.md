# Ground station ↔ interceptor interface

> **Status: TENTATIVE (contract v0.1.0).** The payload encoding is deliberately
> undecided — both options are documented. The transport, ports and frame
> conventions are what the two subteams agree on today. Numbers here mirror
> `interfaces/contract.py`.

This is the contract between the **ground-station subteam** (video in → target
track out) and the **interceptor / air side** (target track in → aircraft
commands). The [`fake_gs/`](../fake_gs/README.md) oracle implements this
contract *now* using simulated ground truth, so the air side can be developed
before the real detector exists. When the real ground station lands, its
publisher replaces the oracle with **no change to the interceptor side**.

```
   video (BoxPro+ WiFi / sim)            ┌─ oracle (now)  ─────────┐
GS ──────────────────────────▶ detector ─┤                          ├─▶ interceptor
                                         └─ real ground station ────┘     (SITL / FC)
                                    target track over MAVLink
```

## Transport

- **Protocol:** MAVLink v2 over **UDP**.
- **Direction:** ground station → interceptor (one way for the target track).
- **Endpoint:** the interceptor's MAVLink endpoint. In sim, SITL's `serial0`
  TCP server accepts multiple clients, so a producer connects as a GCS; on real
  hardware the producer sends to the FC's telemetry link.
- **Source ids:** producers send with `sysid = 255`, `compid = 190`
  (`GCS_COMPONENT_ID` in `contract.py`), target `sysid = 1`.

## Port map (SITL)

`sim_vehicle.py` gives each instance a +10 block. The helpers in
`interfaces/contract.py` compute these.

| Vehicle | instance | `serial0` (TCP) | MAVProxy (UDP) | oracle feed (UDP) | Gazebo `fdm_port_in` |
|---------|:--------:|:---------------:|:--------------:|:-----------------:|:--------------------:|
| interceptor | 0 | 5760 | 14550 | — | 9002 |
| target      | 1 | 5770 | 14560 | 14561 | 9012 |

The **oracle feed** is where the target SITL emits telemetry for the oracle to
listen on (`--out=udp:127.0.0.1:14561`). It is an implementation detail of the
sim, not part of the GS contract.

## Payload

Two encodings are documented. Pick one when the guidance-location decision is
made. The oracle defaults to **Option A**.

### Option A — `FOLLOW_TARGET` (recommended)

MAVLink `FOLLOW_TARGET` (id 144). ArduPilot already consumes it via
[`AP_Follow`](../external/ardupilot/libraries/AP_Follow/) — it is the native
"here is a thing to follow" message and matches the *ranging + pursue to
contact* requirement (the GS estimates range → global position).

| Field | Units | Meaning |
|-------|-------|---------|
| `timestamp` | us | source timestamp (monotonic receiver clock) |
| `est_capabilities` | — | bitmask of which fields the GS actually estimates; set the bits for the fields you fill |
| `lat`, `lon` | degE7 | target position |
| `alt` | m | target altitude (AMS above MSL) |
| `vel[3]` | m/s | target NED velocity (set `est_capabilities` bit) |
| `acc[3]` | m/s² | target NED acceleration |
| `attitude_q[4]` | — | target attitude quaternion (optional) |
| `rates[3]` | rad/s | target body rates (optional) |
| `position_cov[3]` | m² | position covariance (optional) |

Notes:
- `FOLLOW_TARGET` is a **broadcast** message (no target_system field).
- Only advertise capabilities you actually estimate. A bearing/range-only
  detector must **not** claim global position it cannot produce — see the
  ranging note below.

### Option B — GUIDED setpoints

The GS (or this repo's `guidance/`) computes the command and sends one of:

- `SET_POSITION_TARGET_LOCAL_NED` (id 84) — position/velocity/accel setpoint in
  the interceptor's local NED frame, or
- `SET_ATTITUDE_TARGET` (id 82) — attitude/thrust setpoint.

Use this only when guidance runs **on the ground** and you want the interceptor
in GUIDED. Requires the interceptor to be in a mode that accepts offboard
setpoints (`GUIDED`).

## Ranging and frame caveat

The interceptor's camera gives a **relative bearing** and, with a known target
size, a **range**. Both options above express a target in a **global** frame, so
someone on the GS side must combine bearing+range with the interceptor's own
position to produce `lat/lon/alt` (Option A) or local-NED (Option B). Make this
explicit in the detector team's design; it is the crux of "ranging".

## Rates and latency

| Message | Rate |
|---------|-----:|
| target track | 10 Hz (Option A) |
| setpoints | 20 Hz (Option B) |
| interceptor telemetry (for the GS) | 10 Hz |

Budget (design targets, to be measured):

| Stage | Budget |
|-------|-------:|
| camera capture → frames delivered | TBD |
| detection + tracking | TBD |
| ranging/geometry | TBD |
| GS → interceptor link | ~30 ms (LAN/UDP) |
| **total sense→command** | **TBD (must be < pursuit law time constant)** |

## Versioning

- `CONTRACT_VERSION` in `interfaces/contract.py` is the machine-readable
  version.
- Adding an optional message/field = minor. Changing units, ports or removing a
  field = major + a note in the commit body.
