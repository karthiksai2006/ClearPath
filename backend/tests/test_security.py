"""Security and abuse resistance test suite for ClearPath."""

import time
from fastapi.testclient import TestClient
from backend.app.auth import (
    LOCKOUT_WINDOW_SECONDS,
    MAX_FAILED_ATTEMPTS,
    is_rate_limited,
    reset_all_sessions,
    verify_emergency_passcode,
)
from backend.app.main import app

client = TestClient(app)


def setup_function():
    reset_all_sessions()


def test_security_headers_present():
    """Verify production security headers are attached to all API responses."""
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.headers.get("x-content-type-options") == "nosniff"
    assert resp.headers.get("x-frame-options") == "DENY"
    assert "strict-origin" in resp.headers.get("referrer-policy", "")


def test_brute_force_lockout():
    """Verify that 5 failed authentication attempts lock out an ambulance ID."""
    amb_id = "AMB-ATTACKER-99"

    # Make MAX_FAILED_ATTEMPTS invalid attempts
    for i in range(MAX_FAILED_ATTEMPTS):
        resp = client.post(
            "/api/ambulance/session/start",
            json={"ambulance_id": amb_id, "passcode": f"WRONG_PASS_{i}"},
        )
        assert resp.status_code == 401

    # 6th attempt: should be rejected with 429 Too Many Requests (Lockout active)
    resp = client.post(
        "/api/ambulance/session/start",
        json={"ambulance_id": amb_id, "passcode": "CLEARPATH-EMERGENCY-2026"},
    )
    assert resp.status_code == 429
    assert "Too many failed" in resp.json()["detail"]


def test_dos_long_passcode_payload_rejected():
    """Verify that buffer-overflow / DoS oversized payloads are cleanly rejected."""
    huge_passcode = "A" * 10000
    assert verify_emergency_passcode(huge_passcode) is False
    resp = client.post(
        "/api/ambulance/session/start",
        json={"ambulance_id": "AMB-01", "passcode": huge_passcode},
    )
    assert resp.status_code == 401


def test_session_token_cryptographic_randomness():
    """Verify session tokens are unique, unguessable hex strings."""
    tokens = set()
    for i in range(10):
        resp = client.post(
            "/api/ambulance/session/start",
            json={"ambulance_id": f"AMB-{i}", "passcode": "CLEARPATH-EMERGENCY-2026"},
        )
        assert resp.status_code == 200
        token = resp.json()["session_token"]
        assert token.startswith("EMG-")
        assert token not in tokens
        tokens.add(token)
    assert len(tokens) == 10
