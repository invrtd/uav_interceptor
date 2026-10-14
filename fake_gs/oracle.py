#!/usr/bin/env python3
"""Oracle ground station (THROWAWAY — see fake_gs/README.md).

Stands in for the not-yet-built detector: reads the *target* vehicle's true
state over MAVLink and republishes it to the *interceptor* as the message the
real ground station will send. The interceptor side cannot tell the difference.

    target  --GLOBAL_POSITION_INT-->  this  --FOLLOW_TARGET-->  interceptor
      udp :14561                              tcp :5760

Invoked by `make fake-gs`; ports/sysids come from interfaces/contract.py.
"""

from __future__ import annotations

import argparse
import sys
import time

from pymavlink import mavutil

# Allow running as `python fake_gs/oracle.py` from the repo root.
sys.path.insert(0, str(__import__("pathlib").Path(__file__).resolve().parent.parent))
from interfaces import contract  # noqa: E402

# FOLLOW_TARGET est_capabilities bit positions (common.xml id 144).
CAP_POS = 1 << 0
CAP_VEL = 1 << 1


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Oracle ground station (sim only).")
    p.add_argument(
        "--target", default=f"udpin:0.0.0.0:{contract.TARGET.oracle_feed_port}",
        help="MAVLink endpoint receiving the target vehicle's telemetry",
    )
    p.add_argument(
        "--interceptor", default=f"tcp:127.0.0.1:{contract.INTERCEPTOR.mavlink_tcp_port}",
        help="MAVLink endpoint of the interceptor vehicle (GCS client)",
    )
    p.add_argument(
        "--rate", type=float, default=float(contract.RATE_FOLLOW_TARGET_HZ),
        help="FOLLOW_TARGET publish rate (Hz)",
    )
    return p.parse_args()


def main() -> int:
    args = parse_args()

    print(f">> listening for target telemetry on {args.target}")
    target = mavutil.mavlink_connection(args.target)

    print(f">> connecting to interceptor on {args.interceptor}")
    interceptor = mavutil.mavlink_connection(
        args.interceptor,
        source_system=255,
        source_component=contract.GCS_COMPONENT_ID,
    )

    print(f">> oracle up: target(sysid={contract.TARGET.sysid}) -> "
          f"interceptor(sysid={contract.INTERCEPTOR.sysid}) at {args.rate:g} Hz")
    print("   waiting for GLOBAL_POSITION_INT from the target (is it armed/flying?)")

    period = 1.0 / args.rate
    last_heartbeat = 0.0
    sent = 0
    last = None

    while True:
        # Drain everything the target has sent; keep the newest position.
        msg = target.recv_match(type="GLOBAL_POSITION_INT", blocking=True, timeout=1.0)
        while msg is not None:
            last = msg
            msg = target.recv_match(type="GLOBAL_POSITION_INT", blocking=False)

        now = time.monotonic()

        # Keep the interceptor's GCS link healthy.
        if now - last_heartbeat > 1.0:
            interceptor.mav.heartbeat_send(
                mavutil.mavlink.MAV_TYPE_GCS,
                mavutil.mavlink.MAV_AUTOPILOT_INVALID,
                0, 0, 0,
            )
            last_heartbeat = now

        if last is None:
            continue

        # GLOBAL_POSITION_INT: lat/lon degE7, alt mm, vx/vy/vz cm/s (NED).
        # FOLLOW_TARGET:       lat/lon degE7, alt m,   vel m/s (NED).
        caps = CAP_POS | CAP_VEL
        interceptor.mav.follow_target_send(
            int(last.time_boot_ms),          # timestamp (ms) — controller clock
            caps,
            last.lat,
            last.lon,
            last.alt / 1000.0,
            [last.vx / 100.0, last.vy / 100.0, last.vz / 100.0],
            [0.0, 0.0, 0.0],                 # acc: unknown
            [1.0, 0.0, 0.0, 0.0],            # attitude_q: identity/unknown
            [0.0, 0.0, 0.0],                 # rates: unknown
            [0.0, 0.0],                      # position_cov: unknown
        )
        sent += 1
        if sent % (int(args.rate) * 5) == 0:
            print(f"   sent {sent} FOLLOW_TARGET "
                  f"(target {last.lat*1e-7:.7f}, {last.lon*1e-7:.7f}, "
                  f"{last.alt/1000.0:.1f} m)")

        time.sleep(period)


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        print("\n>> oracle stopped")
