# Architecture

The project is a **monorepo** with one hard boundary: the MAVLink contract in
[`docs/interface.md`](interface.md). Everything on one side of that boundary is
owned by the interceptor (air + sim) team; everything on the other by the
ground-station subteam. The two sides never import each other's code.

## Owners

| Area | Directory | Owner |
|------|-----------|-------|
| Sim platform (SITL + Gazebo bring-up) | `scripts/`, `config/`, `external/` | interceptor team |
| Wire contract | `interfaces/`, `docs/interface.md` | **joint** — changes need both |
| Guidance / pursuit law | `guidance/` | interceptor team |
| Oracle (stand-in ground station) | `fake_gs/` | interceptor team — **temporary** |
| Onboard Lua (optional) | `onboard/` | interceptor team |
| Video ingest + detection | *(other subteam's repo)* | ground-station subteam |

## The loop

`GROUND-IN-THE-LOOP`: only the camera comes down to the ground; the detector and
guidance run on the ground PC; the loop closes back up over MAVLink.

```
                        ┌─────────────────────── ground PC ────────────────────────┐
                        │                                                           │
  interceptor (SITL/FC) │   ┌──────────────┐   frames   ┌───────────┐   track       │
  ┌───────────────────┐ │   │ video source │───────────▶│ detector  │──────────┐    │
  │ ArduPilot vehicle │ │   └──────────────┘            └───────────┘          │    │
  │  (interceptor)    │ │          ▲                                           ▼    │
  │  camera ──────────┼─┼──RTP/H264│                              ┌─────────────────┐│
  │                   │ │          │                              │  tracking +     ││
  │  MAVLink  ◀───────┼─┼──────────┼──────────────────────────────│  ranging +      ││
  └───────────────────┘ │          │        setpoints /           │  guidance       ││
                        │          │        FOLLOW_TARGET         └─────────────────┘│
                        └──────────┼──────────────────────────────────────────────────┘
                                   │
            ┌──────────────────────┴───────────────────────┐
            │ target UAV (SITL), scripted or human-flown   │
            └──────────────────────────────────────────────┘
```

In the **fake** configuration, the "detector/tracking/ranging/guidance" box is
replaced by `fake_gs/oracle.py`, which reads the target's true state over
MAVLink and emits the same track the real pipeline will.

## Why a MAVLink boundary (decoupling)

- ArduPilot already speaks MAVLink and already understands `FOLLOW_TARGET`
  (`libraries/AP_Follow`), so no glue code is shared.
- The subteams can iterate, use different languages/environments, and even live
  in different repos without coordination.
- The oracle is a *drop-in*: it implements the same contract, so swapping it for
  the real ground station is a config change, not a code change.

## The oracle is throwaway

`fake_gs/` must stay small and obviously temporary. It should never grow
detection logic — the moment the real detector exists, delete it. It is marked
as such in `fake_gs/README.md`.

## Guidance placement (deferred)

Where the pursuit law runs is **not decided**. The repo keeps that open by
making the contract the boundary. Candidate placements (see
`external/ardupilot` references):

- **Ground (default for now):** `guidance/` on the PC emits GUIDED setpoints or
  `FOLLOW_TARGET` (Option B / A).
- **Onboard via Lua:** `onboard/*.lua` in `AP_Scripting` (needs `SCR_ENABLE=1`,
  Copter custom mode `n>100`). Nothing to recompile.
- **Onboard fork:** a custom mode / `AC_CustomControl` backend — requires a
  fork; avoid until justified.

## Latency

The sense→command loop must be faster than the pursuit law's time constant.
Budgets are placeholders in `docs/interface.md`; fill them in once the video
path is measured (the H.264 stream adds encode+transport latency — prefer raw
frames via `gz.transport` for the sim if latency matters, see
`docs/sim-bringup.md`).
