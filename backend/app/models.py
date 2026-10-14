"""Pydantic data models for ClearPath."""

from enum import Enum
from typing import List, Optional
from pydantic import BaseModel, Field


class VehicleType(str, Enum):
    AMBULANCE = "AMBULANCE"
    CIVILIAN = "CIVILIAN"


class Coordinates(BaseModel):
    latitude: float = Field(..., description="Latitude in decimal degrees", ge=-90.0, le=90.0)
    longitude: float = Field(..., description="Longitude in decimal degrees", ge=-180.0, le=180.0)
    speed_mps: float = Field(default=0.0, description="Speed in metres per second", ge=0.0)
    heading_degrees: float = Field(default=0.0, description="Heading in degrees (0-360)", ge=0.0, le=360.0)
    timestamp: float = Field(default=0.0, description="Epoch timestamp of coordinate reading")


class Vehicle(BaseModel):
    id: str = Field(..., description="Unique vehicle identifier")
    name: str = Field(..., description="Human-readable vehicle name")
    type: VehicleType = Field(..., description="Vehicle type: AMBULANCE or CIVILIAN")
    coordinates: Coordinates = Field(..., description="Current vehicle position")
    emergency_active: bool = Field(default=False, description="Whether emergency broadcast mode is active")
    session_token: Optional[str] = Field(default=None, description="Active emergency session token (ambulances only)")


class EmergencySessionStartRequest(BaseModel):
    ambulance_id: str = Field(..., description="Identifier of the ambulance starting emergency")
    passcode: str = Field(..., description="Security authorization passcode")


class EmergencySessionStopRequest(BaseModel):
    ambulance_id: str = Field(..., description="Identifier of the ambulance stopping emergency")
    session_token: str = Field(..., description="Authorized session token")


class EmergencySessionResponse(BaseModel):
    success: bool
    ambulance_id: str
    session_token: Optional[str] = None
    is_active: bool
    message: str


class ProximityAlert(BaseModel):
    alert_id: str
    vehicle_id: str
    ambulance_id: str
    distance_meters: float
    distance_feet: float
    is_alert_active: bool
    message: str
    timestamp: float


class SimulationState(BaseModel):
    is_running: bool
    step_count: int
    speed_multiplier: float
    vehicles: List[Vehicle]
    active_alerts: List[ProximityAlert]


class LocationUpdateRequest(BaseModel):
    vehicle_id: str
    coordinates: Coordinates
    emergency_active: bool = False
    session_token: Optional[str] = None
