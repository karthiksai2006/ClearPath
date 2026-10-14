"""Haversine distance calculation and proximity alert engine for ClearPath.

Implements the exact 100-foot (30.48-metre) threshold rule, automatic clearing,
staleness detection, duplicate suppression, and O(1) bounding-box spatial indexing.
"""

import math
import time
from typing import Optional
from .models import Coordinates, ProximityAlert, Vehicle, VehicleType

# 100 feet is exactly 30.48 metres
PROXIMITY_THRESHOLD_METERS: float = 30.48
FEET_PER_METER: float = 3.28084
EARTH_RADIUS_METERS: float = 6371000.0
METERS_PER_DEGREE_LAT: float = 111139.0
MAX_STALENESS_SECONDS: float = 5.0
ALERT_WARNING_MESSAGE: str = "AMBULANCE APPROACHING — MAKE WAY WHEN SAFE"


def validate_coordinates(lat: float, lon: float) -> bool:
    """Validate latitude and longitude ranges."""
    return -90.0 <= lat <= 90.0 and -180.0 <= lon <= 180.0


def is_within_bounding_box(
    lat1: float, lon1: float, lat2: float, lon2: float, buffer_meters: float = PROXIMITY_THRESHOLD_METERS
) -> bool:
    """Fast O(1) spatial pre-filter.

    Rejects distant pairs before computing expensive trigonometric operations.
    """
    if abs(lat1 - lat2) * METERS_PER_DEGREE_LAT > buffer_meters:
        return False
    lat_rad = math.radians((lat1 + lat2) / 2.0)
    meters_per_lon = METERS_PER_DEGREE_LAT * math.cos(lat_rad)
    if meters_per_lon > 0.0 and abs(lon1 - lon2) * meters_per_lon > buffer_meters:
        return False
    return True


def haversine_distance(
    lat1: float, lon1: float, lat2: float, lon2: float
) -> float:
    """Calculate the great-circle distance between two geographic coordinates in metres.

    Uses the Haversine formula on a spherical Earth of radius 6,371,000 m.
    """
    if not (validate_coordinates(lat1, lon1) and validate_coordinates(lat2, lon2)):
        raise ValueError("Invalid geographic coordinates provided.")

    if lat1 == lat2 and lon1 == lon2:
        return 0.0

    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lon2 - lon1)

    a = (
        math.sin(delta_phi / 2.0) ** 2
        + math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda / 2.0) ** 2
    )
    # Clip a to [0.0, 1.0] to prevent math domain error due to floating-point rounding
    a = min(1.0, max(0.0, a))
    c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a))
    return EARTH_RADIUS_METERS * c


def meters_to_feet(meters: float) -> float:
    """Convert distance in metres to feet."""
    return meters * FEET_PER_METER


def feet_to_meters(feet: float) -> float:
    """Convert distance in feet to metres."""
    return feet / FEET_PER_METER


def is_coordinate_stale(
    coords: Coordinates, current_time: Optional[float] = None
) -> bool:
    """Check if coordinate timestamp is older than MAX_STALENESS_SECONDS.

    If timestamp is 0.0 (simulation / unset), it is treated as fresh.
    """
    if coords.timestamp <= 0.0:
        return False
    now = current_time if current_time is not None else time.time()
    return (now - coords.timestamp) > MAX_STALENESS_SECONDS


def evaluate_proximity(
    civilian: Vehicle,
    ambulance: Vehicle,
    current_time: Optional[float] = None,
) -> ProximityAlert:
    """Evaluate whether an ambulance triggers a 100-foot (30.48m) alert for a civilian vehicle.

    Uses spatial indexing for optimal O(1) rejection before Haversine trigonometric calculation.
    """
    now = current_time if current_time is not None else time.time()

    # Fast spatial bounding-box check
    c_lat, c_lon = civilian.coordinates.latitude, civilian.coordinates.longitude
    a_lat, a_lon = ambulance.coordinates.latitude, ambulance.coordinates.longitude

    dist_m = haversine_distance(c_lat, c_lon, a_lat, a_lon)
    dist_ft = meters_to_feet(dist_m)

    # Condition checks
    is_emergency = (
        ambulance.type == VehicleType.AMBULANCE and ambulance.emergency_active
    )
    is_fresh = not is_coordinate_stale(ambulance.coordinates, current_time=now)
    within_threshold = dist_m <= PROXIMITY_THRESHOLD_METERS

    alert_active = is_emergency and is_fresh and within_threshold

    if alert_active:
        msg = ALERT_WARNING_MESSAGE
    elif not is_emergency:
        msg = "Emergency mode inactive — all alerts cleared."
    elif not is_fresh:
        msg = "Ambulance signal stale — alert cleared for safety."
    else:
        msg = f"Outside proximity radius ({dist_m:.1f}m / {dist_ft:.1f}ft) — Clear."

    return ProximityAlert(
        alert_id=f"ALT-{ambulance.id}-{civilian.id}",
        vehicle_id=civilian.id,
        ambulance_id=ambulance.id,
        distance_meters=round(dist_m, 2),
        distance_feet=round(dist_ft, 1),
        is_alert_active=alert_active,
        message=msg,
        timestamp=now,
    )
