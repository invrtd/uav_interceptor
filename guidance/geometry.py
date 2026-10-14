"""Camera geometry: turn a detection into a bearing and (with a known target
size) a range. This is the ground-side half of "ranging".

Nothing here talks to MAVLink or Gazebo; it is pure math so it can be unit
tested and reused by the ground-station subteam.
"""

from __future__ import annotations

import math
from dataclasses import dataclass

import numpy as np


@dataclass(frozen=True)
class Intrinsics:
    """Pinhole camera intrinsics (pixels)."""

    fx: float
    fy: float
    cx: float
    cy: float

    @classmethod
    def from_fov(cls, width: int, height: int, hfov_deg: float) -> "Intrinsics":
        """Build intrinsics from image size and horizontal field of view."""
        fx = (width / 2.0) / math.tan(math.radians(hfov_deg) / 2.0)
        return cls(fx=fx, fy=fx, cx=width / 2.0, cy=height / 2.0)


@dataclass(frozen=True)
class BBox:
    """Axis-aligned bounding box in pixels (top-left origin)."""

    x0: float
    y0: float
    x1: float
    y1: float

    @property
    def center(self) -> tuple[float, float]:
        return ((self.x0 + self.x1) / 2.0, (self.y0 + self.y1) / 2.0)

    @property
    def width(self) -> float:
        return abs(self.x1 - self.x0)

    @property
    def height(self) -> float:
        return abs(self.y1 - self.y0)


def bearing_from_bbox(bbox: BBox, intr: Intrinsics) -> tuple[float, float]:
    """Bearing of the bbox centre as (azimuth, elevation) in radians.

    Azimuth is positive to the right of the camera boresight; elevation is
    positive up. Camera axes: +x right, +y down, +z forward.
    """
    u, v = bbox.center
    az = math.atan2(u - intr.cx, intr.fx)
    el = math.atan2(intr.cy - v, intr.fy)
    return az, el


def range_from_bbox(bbox: BBox, intr: Intrinsics, target_size_m: float,
                    axis: str = "width") -> float:
    """Estimate range from the apparent size of a known-size target.

    Uses the pinhole relation ``range = f * size / pixel_size``. Returns
    ``math.inf`` when the apparent size is degenerate.
    """
    px = bbox.width if axis == "width" else bbox.height
    f = intr.fx if axis == "width" else intr.fy
    if px <= 0.0:
        return math.inf
    return f * target_size_m / px


def range_from_position(rel_ned: np.ndarray) -> float:
    """Slant range to a target given its relative position (NED metres)."""
    return float(np.linalg.norm(np.asarray(rel_ned, dtype=float)))
