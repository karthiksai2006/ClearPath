"""Authentication, session validation, and brute-force security defense for ClearPath.

Implements constant-time passcode verification, brute-force rate-limiting,
and cryptographically secure session issuance.
"""

from collections import defaultdict
import secrets
import time
from typing import Dict, List, Optional

# Authorized passcodes for prototype demonstration
VALID_EMERGENCY_PASSCODES = {
    "CLEARPATH-EMERGENCY-2026",
    "AMB-911-SECURE",
    "RESCUE-DEMO-100",
}

# In-memory session store: session_token -> dict(ambulance_id, created_at, is_active)
_ACTIVE_SESSIONS: Dict[str, dict] = {}

# Brute-force protection: ambulance_id -> list of failed attempt timestamps
_FAILED_ATTEMPTS: Dict[str, List[float]] = defaultdict(list)
MAX_FAILED_ATTEMPTS = 5
LOCKOUT_WINDOW_SECONDS = 60.0


def is_rate_limited(ambulance_id: str, current_time: Optional[float] = None) -> bool:
    """Check if an ambulance_id is temporarily locked out due to repeated invalid passcodes."""
    now = current_time if current_time is not None else time.time()
    # Filter attempts within the window
    attempts = [t for t in _FAILED_ATTEMPTS[ambulance_id] if (now - t) < LOCKOUT_WINDOW_SECONDS]
    _FAILED_ATTEMPTS[ambulance_id] = attempts
    return len(attempts) >= MAX_FAILED_ATTEMPTS


def record_failed_attempt(ambulance_id: str, current_time: Optional[float] = None) -> None:
    """Record a failed authentication attempt."""
    now = current_time if current_time is not None else time.time()
    _FAILED_ATTEMPTS[ambulance_id].append(now)


def reset_failed_attempts(ambulance_id: str) -> None:
    """Reset lockout upon successful authentication."""
    _FAILED_ATTEMPTS.pop(ambulance_id, None)


def verify_emergency_passcode(passcode: str) -> bool:
    """Constant-time verification of supplied passcode against authorized credentials.

    Uses secrets.compare_digest to defend against side-channel timing attacks.
    """
    clean_pass = passcode.strip()
    if len(clean_pass) > 128:  # Prevent memory exhaustion/DoS
        return False

    return any(
        secrets.compare_digest(clean_pass, valid_code)
        for valid_code in VALID_EMERGENCY_PASSCODES
    )


def create_emergency_session(ambulance_id: str, passcode: str) -> Optional[str]:
    """Create a verified emergency session token for an ambulance with rate-limiting."""
    clean_id = ambulance_id.strip()
    if is_rate_limited(clean_id):
        return None

    if not verify_emergency_passcode(passcode):
        record_failed_attempt(clean_id)
        return None

    reset_failed_attempts(clean_id)

    # Revoke any prior session for this ambulance
    for token, session in list(_ACTIVE_SESSIONS.items()):
        if session["ambulance_id"] == clean_id:
            session["is_active"] = False

    session_token = f"EMG-{secrets.token_hex(16)}"
    _ACTIVE_SESSIONS[session_token] = {
        "ambulance_id": clean_id,
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
    _FAILED_ATTEMPTS.clear()
