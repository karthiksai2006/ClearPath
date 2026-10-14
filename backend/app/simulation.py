"""Road simulation engine with multiple vehicles moving along a corridor.

Enables automated or manual stepping to verify the 100-foot (30.48m) activation
and automatic clearing behavior.
"""

import math
import time
from typing import Dict, List, Optional
from .models import (
    Coordinates,
    ProximityAlert,
    SimulationState,
    Vehicle,
    VehicleType,
)
from .proximity import evaluate_proximity, haversine_distance

# Base anchor coordinate (Urban corridor reference: Bangalore Central / MG Road corridor)
BASE_LATITUDE: float = 12.9715987
BASE_LONGITUDE: float = 77.5945627

# Conversion constants for small flat-earth offsets
METERS_PER_DEGREE_LAT: float = 111139.0


# Type alias helper
Tuple_Coordinates = tuple[float, float]


def offset_to_coordinates(
    dx_meters: float,
    dy_meters: float,
    base_lat: float = BASE_LATITUDE,
    base_lon: float = BASE_LONGITUDE,
) -> Tuple_Coordinates:
    """Convert Cartesian offsets (dx: East, dy: North) in metres to geographic coordinates."""
    d_lat = dy_meters / METERS_PER_DEGREE_LAT
    lat_rad = math.radians(base_lat)
    d_lon = dx_meters / (METERS_PER_DEGREE_LAT * math.cos(lat_rad))
    return base_lat + d_lat, base_lon + d_lon


class RoadSimulation:
    """Manages a simulated straight corridor with an ambulance and civilian vehicles."""

    def __init__(self) -> None:
        self.is_running: bool = False
        self.step_count: int = 0
        self.speed_multiplier: float = 1.0
        self.corridor_length_meters: float = 300.0

        # Ambulance initial position (meters along road, traveling eastward)
        self.amb_position_m: float = 0.0
        self.amb_speed_mps: float = 10.0  # 36 km/h
        self.amb_emergency_active: bool = True

        # Civilian vehicles stationary or cruising along the corridor
        # Position in metres along the corridor
        self.civilian_configs = [
            {"id": "CAR-01", "name": "Civic Sedan", "pos_m": 60.0, "speed_mps": 0.0},
            {"id": "CAR-02", "name": "Delivery Van", "pos_m": 130.0, "speed_mps": 2.0},
            {"id": "CAR-03", "name": "EV Hatchback", "pos_m": 210.0, "speed_mps": 0.0},
        ]
        self.civilian_positions: Dict[str, float] = {
            cfg["id"]: cfg["pos_m"] for cfg in self.civilian_configs
        }

        self.vehicles: Dict[str, Vehicle] = {}
        self.active_alerts: List[ProximityAlert] = []
        self._sync_vehicle_objects()

    def _sync_vehicle_objects(self) -> None:
        """Update Vehicle model instances with current positions."""
        now = time.time()

        # Ambulance
        amb_lat, amb_lon = offset_to_coordinates(
            dx_meters=self.amb_position_m, dy_meters=0.0
        )
        self.vehicles["AMB-01"] = Vehicle(
            id="AMB-01",
            name="Emergency Rescue 1",
            type=VehicleType.AMBULANCE,
            coordinates=Coordinates(
                latitude=amb_lat,
                longitude=amb_lon,
                speed_mps=self.amb_speed_mps if self.is_running else 0.0,
                heading_degrees=90.0,  # Eastward
                timestamp=now,
            ),
            emergency_active=self.amb_emergency_active,
            session_token="EMG-SIMULATION-TOKEN",
        )

        # Civilians
        for cfg in self.civilian_configs:
            v_id = cfg["id"]
            pos_m = self.civilian_positions[v_id]
            c_lat, c_lon = offset_to_coordinates(dx_meters=pos_m, dy_meters=0.0)
            self.vehicles[v_id] = Vehicle(
                id=v_id,
                name=cfg["name"],
                type=VehicleType.CIVILIAN,
                coordinates=Coordinates(
                    latitude=c_lat,
                    longitude=c_lon,
                    speed_mps=cfg["speed_mps"],
                    heading_degrees=90.0,
                    timestamp=now,
                ),
                emergency_active=False,
            )

        # Recalculate proximity alerts for all civilian vehicles
        ambulance = self.vehicles["AMB-01"]
        alerts: List[ProximityAlert] = []
        for cfg in self.civilian_configs:
            civ = self.vehicles[cfg["id"]]
            alert = evaluate_proximity(civ, ambulance, current_time=now)
            alerts.append(alert)
        self.active_alerts = alerts

    def step(self, dt_seconds: float = 1.0) -> SimulationState:
        """Advance simulation by dt_seconds."""
        effective_dt = dt_seconds * self.speed_multiplier

        # Move ambulance
        self.amb_position_m += self.amb_speed_mps * effective_dt
        if self.amb_position_m > self.corridor_length_meters:
            # Wrap around corridor for continuous demonstration
            self.amb_position_m = 0.0

        # Move civilians with non-zero speed
        for cfg in self.civilian_configs:
            v_id = cfg["id"]
            speed = cfg["speed_mps"]
            if speed > 0:
                self.civilian_positions[v_id] += speed * effective_dt
                if self.civilian_positions[v_id] > self.corridor_length_meters:
                    self.civilian_positions[v_id] = 50.0

        self.step_count += 1
        self._sync_vehicle_objects()
        return self.get_state()

    def set_emergency_mode(self, active: bool) -> SimulationState:
        """Toggle ambulance emergency mode in the simulation."""
        self.amb_emergency_active = active
        self._sync_vehicle_objects()
        return self.get_state()

    def set_ambulance_position(self, pos_meters: float) -> SimulationState:
        """Manually place ambulance at specific road metre (useful for deterministic tests)."""
        self.amb_position_m = max(0.0, min(self.corridor_length_meters, pos_meters))
        self._sync_vehicle_objects()
        return self.get_state()

    def start(self) -> None:
        self.is_running = True

    def pause(self) -> None:
        self.is_running = False

    def reset(self) -> SimulationState:
        """Reset simulation back to initial starting line."""
        self.is_running = False
        self.step_count = 0
        self.amb_position_m = 0.0
        self.amb_emergency_active = True
        self.civilian_positions = {
            cfg["id"]: cfg["pos_m"] for cfg in self.civilian_configs
        }
        self._sync_vehicle_objects()
        return self.get_state()

    def get_state(self) -> SimulationState:
        """Return current simulation snapshot."""
        return SimulationState(
            is_running=self.is_running,
            step_count=self.step_count,
            speed_multiplier=self.speed_multiplier,
            vehicles=list(self.vehicles.values()),
            active_alerts=self.active_alerts,
        )


# Global singleton instance for simulation API
simulation_engine = RoadSimulation()
