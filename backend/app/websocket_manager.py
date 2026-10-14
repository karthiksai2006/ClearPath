"""WebSocket connection manager for real-time telemetry and proximity alerts."""

import json
import logging
from typing import Any, Dict, List, Set
from fastapi import WebSocket

logger = logging.getLogger("clearpath.ws")


class WebSocketManager:
    """Tracks active WebSockets and coordinates real-time event broadcasting."""

    def __init__(self) -> None:
        # All connected clients
        self.active_connections: Set[WebSocket] = set()
        # Optional metadata mapping WebSocket -> dict(client_type, vehicle_id)
        self.connection_meta: Dict[WebSocket, Dict[str, Any]] = {}

    async def connect(
        self, websocket: WebSocket, client_type: str = "GENERIC", vehicle_id: str = ""
    ) -> None:
        """Accept incoming connection and register in pool."""
        await websocket.accept()
        self.active_connections.add(websocket)
        self.connection_meta[websocket] = {
            "client_type": client_type,
            "vehicle_id": vehicle_id,
        }
        logger.info(
            f"Client connected: type={client_type}, vehicle={vehicle_id}. Total: {len(self.active_connections)}"
        )

    def disconnect(self, websocket: WebSocket) -> None:
        """Remove disconnected client."""
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)
        self.connection_meta.pop(websocket, None)
        logger.info(f"Client disconnected. Remaining: {len(self.active_connections)}")

    async def send_personal_message(self, message: dict, websocket: WebSocket) -> None:
        """Send JSON message directly to a single client."""
        try:
            await websocket.send_text(json.dumps(message))
        except Exception as e:
            logger.warning(f"Failed to send personal message: {e}")

    async def broadcast(self, message: dict) -> None:
        """Broadcast JSON message to all connected clients."""
        dead_connections = []
        payload = json.dumps(message)
        for connection in list(self.active_connections):
            try:
                await connection.send_text(payload)
            except Exception as e:
                logger.warning(f"Broadcast error on client, queuing removal: {e}")
                dead_connections.append(connection)

        for dead in dead_connections:
            self.disconnect(dead)

    async def broadcast_simulation_state(self, state: dict) -> None:
        """Convenience broadcast for simulation state."""
        await self.broadcast({"type": "SIMULATION_STATE", "data": state})

    async def broadcast_alert(self, alert_data: dict) -> None:
        """Broadcast proximity alert to participating devices."""
        await self.broadcast({"type": "PROXIMITY_ALERT", "data": alert_data})


ws_manager = WebSocketManager()
