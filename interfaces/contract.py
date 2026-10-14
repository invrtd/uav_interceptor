"""Wire contract between the ground station and the interceptor.

This module is the SINGLE SOURCE OF TRUTH for the numbers described in
``docs/interface.md``. It is intentionally tiny and stdlib-only so it can be
copied into the ground-station repo without pulling in this repo's environment.

Do not import pymavlink here. Message construction lives with the producers
(``fake_gs/`` and the real ground station).
"""

from __future__ import annotations

from dataclasses import dataclass

# Bump on any breaking change to the contract (see docs/interface.md).
CONTRACT_VERSION = "0.1.0"

# --- SITL port allocation ---------------------------------------------------
# sim_vehicle.py assigns each SITL *instance* a contiguous +10 block.
INSTANCE_STRIDE = 10
MAVLINK_TCP_BASE = 5760       # serial0 server:       tcp:127.0.0.1:<base + 10*i>
MAVPROXY_UDP_BASE = 14550     # MAVProxy/QGC output:  udp:127.0.0.1:<base + 10*i>
ORACLE_FEED_BASE = 14561      # target telemetry -> oracle: udp:127.0.0.1:<base + 10*i>
FDM_PORT_BASE = 9002          # Gazebo ArduPilotPlugin <fdm_port_in>: 9002 + i


@dataclass(frozen=True)
class Vehicle:
    name: str
    instance: int
    sysid: int
    frame: str

    @property
    def mavlink_tcp_port(self) -> int:
        return MAVLINK_TCP_BASE + INSTANCE_STRIDE * self.instance

    @property
    def mavproxy_udp_port(self) -> int:
        return MAVPROXY_UDP_BASE + INSTANCE_STRIDE * self.instance

    @property
    def oracle_feed_port(self) -> int:
        return ORACLE_FEED_BASE + INSTANCE_STRIDE * self.instance

    @property
    def fdm_port(self) -> int:
        """Matches <fdm_port_in> in this vehicle's Gazebo model.

        SITL offsets the JSON FDM port by +10 per instance
        (SIM_OUT_PORT=9002 in AP_HAL_SITL/SITL_cmdline.cpp), so the model must
        agree: instance 0 -> 9002, instance 1 -> 9012.
        """
        return FDM_PORT_BASE + INSTANCE_STRIDE * self.instance


# --- The two vehicles in the sim --------------------------------------------
INTERCEPTOR = Vehicle(name="interceptor", instance=0, sysid=1, frame="gazebo-iris")
TARGET = Vehicle(name="target", instance=1, sysid=2, frame="gazebo-iris")

# Component id used by both producers when speaking to the interceptor.
GCS_COMPONENT_ID = 190


# --- Update rates -----------------------------------------------------------
# Recommended message rates (Hz). Must comfortably exceed the bandwidth the
# pursuit law needs; see docs/interface.md "Rates and latency".
RATE_FOLLOW_TARGET_HZ = 10
RATE_SETPOINT_HZ = 20
RATE_TELEMETRY_HZ = 10


# --- Payload selection ------------------------------------------------------
# The contract documents both encodings; the actual choice depends on where
# guidance runs (still deferred). Producers default to FOLLOW_TARGET.
PAYLOAD_FOLLOW_TARGET = "follow_target"
PAYLOAD_GUIDED_SETPOINTS = "guided_setpoints"
