"""Pursuit / interception laws.

Operates on a :class:`Track` (target state relative to the interceptor, in NED
metres) and produces a desired velocity vector. Placement is still deferred
(ground vs onboard); this module is the ground-side reference implementation
that the contract's Option B setpoints are built from. Pure math, no I/O.
"""

from __future__ import annotations

import math
from dataclasses import dataclass

import numpy as np


@dataclass(frozen=True)
class Track:
    """Target state relative to the interceptor, NED metres and m/s.

    ``rel_ned`` is the *target minus interceptor* position; ``rel_vel`` is the
    target-minus-interceptor velocity (closing speed = -dot(rel_ned, rel_vel)).
    """

    rel_ned: np.ndarray
    rel_vel: np.ndarray


def range_to_target(track: Track) -> float:
    return float(np.linalg.norm(track.rel_ned))


def closing_speed(track: Track) -> float:
    """Positive when the range is shrinking (interceptor gaining on target)."""
    rng = range_to_target(track)
    if rng <= 0.0:
        return 0.0
    return -float(np.dot(track.rel_ned, track.rel_vel)) / rng


def time_to_contact(track: Track, contact_radius_m: float) -> float:
    """Estimated seconds until range reaches ``contact_radius_m``.

    Returns ``math.inf`` when not closing.
    """
    vc = closing_speed(track)
    if vc <= 1e-6:
        return math.inf
    rng = range_to_target(track)
    return max(0.0, (rng - contact_radius_m) / vc)


def pure_pursuit(track: Track, speed_mps: float) -> np.ndarray:
    """Desired interceptor NED velocity: aim straight at the target.

    Closes the range as fast as ``speed_mps`` allows. Simple and robust; a
    starting point before a lead/PN law is needed for moving targets.
    """
    rng = range_to_target(track)
    if rng <= 1e-6:
        return np.zeros(3)
    return (track.rel_ned / rng) * speed_mps


def proportional_navigation(track: Track, speed_mps: float,
                            nav_gain: float = 3.0) -> np.ndarray:
    """Crude proportional-navigation law with a velocity lead.

    Aims at the predicted intercept point (target position plus its velocity
    times time-to-go) instead of the current position, improving hit rate on
    crossing targets. ``nav_gain`` scales the lead.
    """
    rng = range_to_target(track)
    if rng <= 1e-6:
        return np.zeros(3)
    vc = closing_speed(track)
    t_go = rng / vc if vc > 1e-6 else 0.0
    lead = track.rel_vel * (nav_gain * t_go)
    aim = track.rel_ned + lead
    aim_norm = float(np.linalg.norm(aim))
    if aim_norm <= 1e-6:
        return np.zeros(3)
    return (aim / aim_norm) * speed_mps


def intercepting(track: Track, contact_radius_m: float) -> bool:
    """Contact achieved: within the contact radius (the M3 success criterion)."""
    return range_to_target(track) <= contact_radius_m


def demo() -> None:
    """Tiny self-check: a target 30 m ahead moving away at 5 m/s."""
    track = Track(rel_ned=np.array([30.0, 0.0, 0.0]),
                  rel_vel=np.array([5.0, 0.0, 0.0]))
    print(f"range          {range_to_target(track):.1f} m")
    print(f"closing speed  {closing_speed(track):.1f} m/s")
    print(f"time to 1 m    {time_to_contact(track, 1.0):.1f} s")
    print(f"pure pursuit   {pure_pursuit(track, 15.0)}")
    print(f"PN(3.0)        {proportional_navigation(track, 15.0, 3.0)}")


if __name__ == "__main__":
    demo()
