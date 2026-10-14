"""ClearPath FastAPI Backend Application.

Provides REST and WebSocket endpoints for Ambulance Mode, Driver Mode,
and Real-Time Proximity Alert Simulation.
"""

import asyncio
from contextlib import asynccontextmanager
import logging
import time
from typing import Optional

from fastapi import FastAPI, HTTPException, Query, WebSocket, WebSocketDisconnect, status
from fastapi.middleware.cors import CORSMiddleware

from .auth import (
    create_emergency_session,
    is_ambulance_session_active,
    revoke_emergency_session,
    validate_session_token,
)
from .models import (
    Coordinates,
    EmergencySessionResponse,
    EmergencySessionStartRequest,
    EmergencySessionStopRequest,
    LocationUpdateRequest,
    SimulationState,
    Vehicle,
    VehicleType,
)
from .proximity import (
    PROXIMITY_THRESHOLD_METERS,
    evaluate_proximity,
    haversine_distance,
)
from .simulation import simulation_engine
from .websocket_manager import ws_manager

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("clearpath.main")

# Background simulation runner task handle
_simulation_task: Optional[asyncio.Task] = None


async def simulation_loop() -> None:
    """Background ticker that advances simulation when is_running is True."""
    logger.info("Simulation background ticker started.")
    while True:
        try:
            if simulation_engine.is_running:
                state = simulation_engine.step(dt_seconds=0.5)
                await ws_manager.broadcast_simulation_state(state.model_dump())
            await asyncio.sleep(0.5)
        except asyncio.CancelledError:
            break
        except Exception as e:
            logger.error(f"Error in simulation ticker: {e}")
            await asyncio.sleep(1.0)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifecycle startup and shutdown handler."""
    global _simulation_task
    _simulation_task = asyncio.create_task(simulation_loop())
    yield
    if _simulation_task:
        _simulation_task.cancel()
        try:
            await _simulation_task
        except asyncio.CancelledError:
            pass


app = FastAPI(
    title="ClearPath Emergency Proximity Alert API",
    description="Real-world social-impact prototype for ambulance proximity warning.",
    version="1.0.0",
    lifespan=lifespan,
)

# Enable CORS for Flutter Web running on localhost / any port
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health_check():
    """Health check endpoint."""
    return {
        "status": "ok",
        "app": "ClearPath",
        "version": "1.0.0",
        "proximity_threshold_meters": PROXIMITY_THRESHOLD_METERS,
        "proximity_threshold_feet": round(PROXIMITY_THRESHOLD_METERS * 3.28084, 1),
    }


@app.post("/api/ambulance/session/start", response_model=EmergencySessionResponse)
def start_emergency_session(payload: EmergencySessionStartRequest):
    """Authenticate and initiate an ambulance emergency broadcast session."""
    session_token = create_emergency_session(
        ambulance_id=payload.ambulance_id, passcode=payload.passcode
    )
    if not session_token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid emergency dispatcher passcode.",
        )

    # If this matches the simulation ambulance, update simulation state too
    if payload.ambulance_id == "AMB-01":
        simulation_engine.set_emergency_mode(True)

    return EmergencySessionResponse(
        success=True,
        ambulance_id=payload.ambulance_id,
        session_token=session_token,
        is_active=True,
        message="Emergency mode initiated. Location broadcast is active.",
    )


@app.post("/api/ambulance/session/stop", response_model=EmergencySessionResponse)
def stop_emergency_session(payload: EmergencySessionStopRequest):
    """Terminate an ambulance emergency session. Clears all associated alerts immediately."""
    revoked = revoke_emergency_session(
        ambulance_id=payload.ambulance_id, session_token=payload.session_token
    )
    if not revoked:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Invalid session token or ambulance ID.",
        )

    # If this matches simulation ambulance, update simulation
    if payload.ambulance_id == "AMB-01":
        simulation_engine.set_emergency_mode(False)

    return EmergencySessionResponse(
        success=True,
        ambulance_id=payload.ambulance_id,
        session_token=None,
        is_active=False,
        message="Emergency session terminated. All proximity alerts cleared.",
    )


@app.post("/api/simulation/start")
def start_simulation():
    """Start the multi-vehicle road corridor simulation."""
    simulation_engine.start()
    return {"message": "Simulation started", "is_running": True}


@app.post("/api/simulation/pause")
def pause_simulation():
    """Pause the multi-vehicle road corridor simulation."""
    simulation_engine.pause()
    return {"message": "Simulation paused", "is_running": False}


@app.post("/api/simulation/step")
async def step_simulation(dt_seconds: float = 1.0):
    """Advance the simulation by one step manually."""
    state = simulation_engine.step(dt_seconds=dt_seconds)
    await ws_manager.broadcast_simulation_state(state.model_dump())
    return state


@app.post("/api/simulation/reset")
async def reset_simulation():
    """Reset the road simulation to initial starting coordinates."""
    state = simulation_engine.reset()
    await ws_manager.broadcast_simulation_state(state.model_dump())
    return state


@app.post("/api/simulation/emergency")
async def toggle_simulation_emergency(active: bool):
    """Toggle emergency mode on the simulated ambulance."""
    state = simulation_engine.set_emergency_mode(active)
    await ws_manager.broadcast_simulation_state(state.model_dump())
    return state


@app.get("/api/simulation/state", response_model=SimulationState)
def get_simulation_state():
    """Get the current simulation snapshot."""
    return simulation_engine.get_state()


@app.websocket("/ws/telemetry")
async def websocket_telemetry(
    websocket: WebSocket,
    client_type: str = Query("GENERIC"),
    vehicle_id: str = Query(""),
):
    """WebSocket endpoint for real-time bidirectional telemetry and proximity alert streaming."""
    await ws_manager.connect(
        websocket, client_type=client_type, vehicle_id=vehicle_id
    )
    try:
        # Send initial snapshot immediately upon connection
        current_state = simulation_engine.get_state()
        await ws_manager.send_personal_message(
            {"type": "SIMULATION_STATE", "data": current_state.model_dump()},
            websocket,
        )

        while True:
            data = await websocket.receive_text()
            # Handle client heartbeats or client commands
            if data == "ping":
                await ws_manager.send_personal_message(
                    {"type": "PONG", "timestamp": time.time()}, websocket
                )
    except WebSocketDisconnect:
        ws_manager.disconnect(websocket)
    except Exception as e:
        logger.warning(f"WebSocket client loop exception: {e}")
        ws_manager.disconnect(websocket)
