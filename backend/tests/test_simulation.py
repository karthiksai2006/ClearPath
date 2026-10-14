"""Tests for Road Simulation corridor mechanics."""

from backend.app.proximity import PROXIMITY_THRESHOLD_METERS
from backend.app.simulation import RoadSimulation


def test_simulation_initial_state():
    """Verify initial state of vehicles along corridor."""
    sim = RoadSimulation()
    state = sim.get_state()
    assert state.is_running is False
    assert state.step_count == 0
    assert len(state.vehicles) == 4  # 1 ambulance + 3 civilian cars
    assert len(state.active_alerts) == 3


def test_simulation_alerts_activate_and_deactivate_as_ambulance_moves():
    """Verify CAR-01 alert activates as ambulance nears 60m and clears as ambulance leaves."""
    sim = RoadSimulation()

    # Step 1: Place ambulance at 0m. CAR-01 is at 60m (distance 60m > 30.48m)
    sim.set_ambulance_position(0.0)
    car1_alert = next(a for a in sim.active_alerts if a.vehicle_id == "CAR-01")
    assert car1_alert.is_alert_active is False
    assert car1_alert.distance_meters > PROXIMITY_THRESHOLD_METERS

    # Step 2: Place ambulance at 40m. CAR-01 is at 60m (distance 20m <= 30.48m)
    sim.set_ambulance_position(40.0)
    car1_alert = next(a for a in sim.active_alerts if a.vehicle_id == "CAR-01")
    assert car1_alert.is_alert_active is True
    assert car1_alert.distance_meters <= PROXIMITY_THRESHOLD_METERS
    assert car1_alert.message == "AMBULANCE APPROACHING — MAKE WAY WHEN SAFE"

    # Step 3: Place ambulance at 100m. CAR-01 is at 60m (distance 40m > 30.48m)
    sim.set_ambulance_position(100.0)
    car1_alert = next(a for a in sim.active_alerts if a.vehicle_id == "CAR-01")
    assert car1_alert.is_alert_active is False
    assert car1_alert.distance_meters > PROXIMITY_THRESHOLD_METERS

    # At 100m, CAR-02 (at 130m) is 30m away, so CAR-02 alert SHOULD be active
    car2_alert = next(a for a in sim.active_alerts if a.vehicle_id == "CAR-02")
    assert car2_alert.is_alert_active is True


def test_simulation_emergency_mode_toggle():
    """Turning off emergency mode clears alerts even if ambulance is at 60m right beside CAR-01."""
    sim = RoadSimulation()
    sim.set_ambulance_position(60.0)  # Exactly beside CAR-01

    car1_alert = next(a for a in sim.active_alerts if a.vehicle_id == "CAR-01")
    assert car1_alert.is_alert_active is True

    # Turn off emergency mode
    sim.set_emergency_mode(False)
    car1_alert = next(a for a in sim.active_alerts if a.vehicle_id == "CAR-01")
    assert car1_alert.is_alert_active is False
    assert "Emergency mode inactive" in car1_alert.message
