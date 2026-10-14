import 'package:flutter/material.dart';
import '../models/alert_state.dart';

class AlertBanner extends StatefulWidget {
  final AlertStateModel alert;
  final bool fullScreenMode;

  const AlertBanner({
    super.key,
    required this.alert,
    this.fullScreenMode = false,
  });

  @override
  State<AlertBanner> createState() => _AlertBannerState();
}

class _AlertBannerState extends State<AlertBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.alert.isAlertActive) {
      // Inactive/Safe state
      return Semantics(
        label: 'Clear Roadway. No active emergency vehicle within 100 feet proximity radius.',
        container: true,
        child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF132A1D),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.greenAccent.shade700, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle_outline, color: Colors.greenAccent.shade400, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CLEAR ROADWAY — NO NEARBY AMBULANCE',
                    style: TextStyle(
                      color: Colors.greenAccent.shade200,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.alert.message.isNotEmpty
                        ? widget.alert.message
                        : 'ClearPath radar scanning for active emergency broadcasts within 30.48m (100ft)...',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      );
    }

    // Active warning state with accessibility live region announcement
    return Semantics(
      liveRegion: true,
      focused: true,
      label: 'URGENT SAFETY ALERT: AMBULANCE APPROACHING — MAKE WAY WHEN SAFE. Distance is ${widget.alert.distanceMeters.toStringAsFixed(1)} metres.',
      child: ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(widget.fullScreenMode ? 28 : 20),
        decoration: BoxDecoration(
          color: const Color(0xFF7F1D1D), // Dark crimson red
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEF4444), width: 3.5),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.6),
              blurRadius: 28,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.campaign_rounded,
                  color: Colors.white,
                  size: 34,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'EMERGENCY VEHICLE IN PROXIMITY',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.amber.shade300,
                      fontWeight: FontWeight.w900,
                      fontSize: widget.fullScreenMode ? 17 : 14,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'AMBULANCE APPROACHING — MAKE WAY WHEN SAFE',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: widget.fullScreenMode ? 24 : 18,
                letterSpacing: 0.5,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade400, width: 1.2),
              ),
              child: Text(
                'Estimated Proximity: ${widget.alert.distanceMeters.toStringAsFixed(1)} m  (${widget.alert.distanceFeet.toStringAsFixed(0)} ft)',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Proximity threshold <= 30.48m (100 ft). Yield right-of-way safely if applicable.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
