"""Haversine distance calculation and proximity alert engine for ClearPath.

Implements the exact 100-foot (30.48-metre) threshold rule, automatic clearing,
staleness detection, and duplicate suppression.
"""

import math
import time
from typing import Optional, Tuple
from .models import Coordinates, ProximityAlert, Vehicle, VehicleType

# 100 feet is exactly 30.48 metres
PROXIMITY_THRESHOLD_METERS: float = 30.48
FEET_PER_METER: float = 3.28084
EARTH_RADIUS_METERS: float = 6371000.0
MAX_STALENESS_SECONDS: float = 5.0
ALERT_WARNING_MESSAGE: str = "AMBULANCE APPROACHING — MAKE WAY WHEN SAFE"


def haversine_distance(
    lat1: float, lon1: float, lat2: float, lon2: float
) -> float:
    """Calculate the great-circle distance between two geographic coordinates in metres

    Uses the Haversine formula on a spherical Earth of radius 6,371,000 m.
    """
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

    Alert is ACTIVE if and only if:
    1. Ambulance is of type AMBULANCE and has emergency_active == True.
    2. Ambulance location coordinates are fresh (not stale).
    3. The Haversine distance between both vehicles is <= 30.48 metres (100 feet).

    In all other cases (out of range, emergency ended, stale data), the alert
    is inactive/cleared.
    """
    now = current_time if current_time is not None else time.time()
    dist_m = haversine_distance(
        civilian.coordinates.latitude,
        civilian.coordinates.longitude,
        ambulance.coordinates.latitude,
        ambulance.coordinates.longitude,
    )
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
