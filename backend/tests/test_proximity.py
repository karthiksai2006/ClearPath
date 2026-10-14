"""Tests for Haversine distance and proximity alert logic."""

import time
import pytest
from backend.app.models import Coordinates, Vehicle, VehicleType
from backend.app.proximity import (
    ALERT_WARNING_MESSAGE,
    PROXIMITY_THRESHOLD_METERS,
    evaluate_proximity,
    feet_to_meters,
    haversine_distance,
    is_coordinate_stale,
    meters_to_feet,
)


def test_haversine_same_point():
    """Distance between identical coordinates should be exactly 0."""
    dist = haversine_distance(12.971598, 77.594562, 12.971598, 77.594562)
    assert dist == 0.0


def test_feet_to_meters_conversion():
    """100 feet should equal exactly 30.48 metres (within floating point precision)."""
    assert round(feet_to_meters(100.0), 2) == 30.48
    assert round(meters_to_feet(30.48), 1) == 100.0


def test_alert_triggered_within_100_feet():
    """When ambulance is within 30.48m (100ft) and emergency is active, alert MUST trigger."""
    now = time.time()
    # Approx 20 metres north: 20 / 111139.0 degrees lat
    lat_offset = 20.0 / 111139.0

    ambulance = Vehicle(
        id="AMB-01",
        name="Ambulance 1",
        type=VehicleType.AMBULANCE,
        coordinates=Coordinates(
            latitude=12.971598,
            longitude=77.594562,
            timestamp=now,
        ),
        emergency_active=True,
    )

    civilian = Vehicle(
        id="CAR-01",
        name="Car 1",
        type=VehicleType.CIVILIAN,
        coordinates=Coordinates(
            latitude=12.971598 + lat_offset,
            longitude=77.594562,
            timestamp=now,
        ),
        emergency_active=False,
    )

    alert = evaluate_proximity(civilian, ambulance, current_time=now)

    assert alert.is_alert_active is True
    assert alert.distance_meters <= PROXIMITY_THRESHOLD_METERS
    assert alert.message == ALERT_WARNING_MESSAGE
    assert alert.vehicle_id == "CAR-01"
    assert alert.ambulance_id == "AMB-01"


def test_alert_inactive_outside_100_feet():
    """When ambulance is beyond 30.48m (100ft), alert MUST NOT trigger (auto-cleared)."""
    now = time.time()
    # Approx 45 metres north: 45 / 111139.0 degrees lat
    lat_offset = 45.0 / 111139.0

    ambulance = Vehicle(
        id="AMB-01",
        name="Ambulance 1",
        type=VehicleType.AMBULANCE,
        coordinates=Coordinates(
            latitude=12.971598,
            longitude=77.594562,
            timestamp=now,
        ),
        emergency_active=True,
    )

    civilian = Vehicle(
        id="CAR-01",
        name="Car 1",
        type=VehicleType.CIVILIAN,
        coordinates=Coordinates(
            latitude=12.971598 + lat_offset,
            longitude=77.594562,
            timestamp=now,
        ),
        emergency_active=False,
    )

    alert = evaluate_proximity(civilian, ambulance, current_time=now)

    assert alert.is_alert_active is False
    assert alert.distance_meters > PROXIMITY_THRESHOLD_METERS
    assert "Outside proximity radius" in alert.message


def test_automatic_clearing_when_emergency_mode_disabled():
    """Even if distance is 5 metres, alert MUST clear if emergency mode is stopped."""
    now = time.time()
    # 5 metres north
    lat_offset = 5.0 / 111139.0

    ambulance = Vehicle(
        id="AMB-01",
        name="Ambulance 1",
        type=VehicleType.AMBULANCE,
        coordinates=Coordinates(
            latitude=12.971598,
            longitude=77.594562,
            timestamp=now,
        ),
        emergency_active=False,  # Emergency stopped
    )

    civilian = Vehicle(
        id="CAR-01",
        name="Car 1",
        type=VehicleType.CIVILIAN,
        coordinates=Coordinates(
            latitude=12.971598 + lat_offset,
            longitude=77.594562,
            timestamp=now,
        ),
        emergency_active=False,
    )

    alert = evaluate_proximity(civilian, ambulance, current_time=now)

    assert alert.is_alert_active is False
    assert "Emergency mode inactive" in alert.message


def test_stale_location_suppresses_alert():
    """If ambulance location timestamp is older than 5.0 seconds, alert is cleared for safety."""
    now = time.time()
    stale_time = now - 10.0  # 10 seconds ago (older than 5s threshold)

    ambulance = Vehicle(
        id="AMB-01",
        name="Ambulance 1",
        type=VehicleType.AMBULANCE,
        coordinates=Coordinates(
            latitude=12.971598,
            longitude=77.594562,
            timestamp=stale_time,
        ),
        emergency_active=True,
    )

    civilian = Vehicle(
        id="CAR-01",
        name="Car 1",
        type=VehicleType.CIVILIAN,
        coordinates=Coordinates(
            latitude=12.971598 + (10.0 / 111139.0),
            longitude=77.594562,
            timestamp=now,
        ),
        emergency_active=False,
    )

    assert is_coordinate_stale(ambulance.coordinates, current_time=now) is True
    alert = evaluate_proximity(civilian, ambulance, current_time=now)
    assert alert.is_alert_active is False
    assert "stale" in alert.message.lower()
