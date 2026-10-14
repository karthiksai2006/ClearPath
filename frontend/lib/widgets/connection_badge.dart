import 'package:flutter/material.dart';
import '../services/websocket_service.dart';

class ConnectionBadge extends StatelessWidget {
  final WsConnectionStatus status;
  final VoidCallback onRetry;

  const ConnectionBadge({
    super.key,
    required this.status,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    String label;
    IconData icon;

    switch (status) {
      case WsConnectionStatus.connected:
        badgeColor = Colors.greenAccent.shade700;
        label = 'LIVE TELEMETRY ACTIVE';
        icon = Icons.wifi;
        break;
      case WsConnectionStatus.connecting:
        badgeColor = Colors.orangeAccent;
        label = 'CONNECTING...';
        icon = Icons.sync;
        break;
      case WsConnectionStatus.error:
        badgeColor = Colors.redAccent;
        label = 'TELEMETRY OFFLINE';
        icon = Icons.error_outline;
        break;
      case WsConnectionStatus.disconnected:
        badgeColor = Colors.grey;
        label = 'DISCONNECTED';
        icon = Icons.wifi_off;
        break;
    }

    return InkWell(
      onTap: (status != WsConnectionStatus.connected) ? onRetry : null,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: badgeColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: badgeColor, width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: badgeColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: badgeColor,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
