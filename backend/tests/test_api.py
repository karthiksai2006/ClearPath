"""Tests for ClearPath FastAPI REST and session endpoints."""

from fastapi.testclient import TestClient
from backend.app.main import app

client = TestClient(app)


def test_health_endpoint():
    """Verify health endpoint returns status and 30.48m threshold."""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert data["app"] == "ClearPath"
    assert data["proximity_threshold_meters"] == 30.48


def test_emergency_session_start_invalid_passcode():
    """Reject emergency session when wrong passcode is provided."""
    response = client.post(
        "/api/ambulance/session/start",
        json={"ambulance_id": "AMB-99", "passcode": "WRONG_SECRET"},
    )
    assert response.status_code == 401
    assert "Invalid emergency" in response.json()["detail"]


def test_emergency_session_lifecycle():
    """Start valid emergency session, then stop it cleanly."""
    # 1. Start session
    start_resp = client.post(
        "/api/ambulance/session/start",
        json={"ambulance_id": "AMB-01", "passcode": "CLEARPATH-EMERGENCY-2026"},
    )
    assert start_resp.status_code == 200
    start_data = start_resp.json()
    assert start_data["success"] is True
    assert start_data["is_active"] is True
    assert start_data["session_token"].startswith("EMG-")
    token = start_data["session_token"]

    # 2. Stop session
    stop_resp = client.post(
        "/api/ambulance/session/stop",
        json={"ambulance_id": "AMB-01", "session_token": token},
    )
    assert stop_resp.status_code == 200
    stop_data = stop_resp.json()
    assert stop_data["success"] is True
    assert stop_data["is_active"] is False

    # 3. Stop session again with same token -> fails (already revoked)
    stop_again_resp = client.post(
        "/api/ambulance/session/stop",
        json={"ambulance_id": "AMB-01", "session_token": token},
    )
    assert stop_again_resp.status_code == 403


def test_simulation_endpoints():
    """Verify simulation controls (state, step, pause, reset)."""
    # Get state
    resp = client.get("/api/simulation/state")
    assert resp.status_code == 200
    state = resp.json()
    assert "vehicles" in state
    assert len(state["vehicles"]) == 4

    # Step simulation
    step_resp = client.post("/api/simulation/step?dt_seconds=1.0")
    assert step_resp.status_code == 200
    new_state = step_resp.json()
    assert new_state["step_count"] >= 1

    # Reset simulation
    reset_resp = client.post("/api/simulation/reset")
    assert reset_resp.status_code == 200
    reset_state = reset_resp.json()
    assert reset_state["step_count"] == 0
    assert reset_state["is_running"] is False
