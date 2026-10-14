"""Authentication and session validation for ClearPath.

Prevents unauthorized/fake ambulance broadcasts by requiring an authorized passcode
to establish an emergency session token.
"""

import secrets
import time
from typing import Dict, Optional

# Authorized passcodes for prototype demonstration
VALID_EMERGENCY_PASSCODES = {
    "CLEARPATH-EMERGENCY-2026",
    "AMB-911-SECURE",
    "RESCUE-DEMO-100",
}

# In-memory session store: session_token -> dict(ambulance_id, created_at, is_active)
_ACTIVE_SESSIONS: Dict[str, dict] = {}


def verify_emergency_passcode(passcode: str) -> bool:
    """Verify if the supplied passcode matches an authorized ambulance dispatcher passcode."""
    return passcode.strip() in VALID_EMERGENCY_PASSCODES


def create_emergency_session(ambulance_id: str, passcode: str) -> Optional[str]:
    """Create a verified emergency session token for an ambulance."""
    if not verify_emergency_passcode(passcode):
        return None

    # Revoke any prior session for this ambulance
    for token, session in list(_ACTIVE_SESSIONS.items()):
        if session["ambulance_id"] == ambulance_id:
            session["is_active"] = False

    session_token = f"EMG-{secrets.token_hex(16)}"
    _ACTIVE_SESSIONS[session_token] = {
        "ambulance_id": ambulance_id,
        "created_at": time.time(),
        "is_active": True,
    }
    return session_token


def validate_session_token(ambulance_id: str, session_token: Optional[str]) -> bool:
    """Check if the session token is valid and active for the specified ambulance."""
    if not session_token or session_token not in _ACTIVE_SESSIONS:
        return False
    session = _ACTIVE_SESSIONS[session_token]
    return session["ambulance_id"] == ambulance_id and session["is_active"]


def revoke_emergency_session(ambulance_id: str, session_token: str) -> bool:
    """End an emergency session for an ambulance."""
    if session_token in _ACTIVE_SESSIONS:
        session = _ACTIVE_SESSIONS[session_token]
        if session["ambulance_id"] == ambulance_id and session["is_active"]:
            session["is_active"] = False
            return True
    return False


def is_ambulance_session_active(ambulance_id: str) -> bool:
    """Check if an ambulance has any currently active emergency session."""
    for session in _ACTIVE_SESSIONS.values():
        if session["ambulance_id"] == ambulance_id and session["is_active"]:
            return True
    return False


def reset_all_sessions() -> None:
    """Helper for testing / reset."""
    _ACTIVE_SESSIONS.clear()
