import 'package:flutter/material.dart';
import '../models/alert_state.dart';
import '../models/vehicle.dart';
import '../services/websocket_service.dart';
import '../widgets/connection_badge.dart';
import '../widgets/safety_disclaimer.dart';

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({super.key});

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  final WebSocketService _wsService = WebSocketService();

  @override
  void initState() {
    super.initState();
    _wsService.addListener(_onServiceUpdate);
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _wsService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRunning = _wsService.isSimulationRunning;
    final ambEmergency = _wsService.ambulanceEmergencyActive;
    final vehicles = _wsService.vehicles;
    final alerts = _wsService.alerts;

    // Find ambulance
    final amb = vehicles.where((v) => v.type == VehicleTypeEnum.ambulance).firstOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFF0B132B),
      appBar: AppBar(
        title: const Text('Road Simulation & 100ft Proximity Visualizer'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ConnectionBadge(
              status: _wsService.status,
              onRetry: () => _wsService.connect(),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SafetyDisclaimerBanner(compact: true),
            const SizedBox(height: 16),

            // Controls Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1C2541),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isRunning ? Colors.amber.shade700 : Colors.green.shade700,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _wsService.toggleSimulation(!isRunning),
                        icon: Icon(isRunning ? Icons.pause : Icons.play_arrow),
                        label: Text(isRunning ? 'PAUSE' : 'PLAY SIMULATION'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                        onPressed: () => _wsService.stepSimulation(),
                        icon: const Icon(Icons.skip_next),
                        label: const Text('STEP +1s'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.white70),
                        onPressed: () => _wsService.resetSimulation(),
                        icon: const Icon(Icons.replay),
                        label: const Text('RESET'),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ambEmergency ? Colors.redAccent : Colors.grey.shade700,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _wsService.toggleSimEmergency(!ambEmergency),
                    icon: Icon(ambEmergency ? Icons.notifications_active : Icons.notifications_off),
                    label: Text(ambEmergency ? 'EMERGENCY: ON' : 'EMERGENCY: OFF'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Visual Road Canvas Card
            Card(
              color: const Color(0xFF1C2541),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Colors.white12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ROADWAY CORRIDOR (300 METRES)',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              '30.48m (100ft) Radius Bubble',
                              style: TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Custom Road Canvas
                    SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: RoadCorridorPainter(
                          vehicles: vehicles,
                          alerts: alerts,
                          ambulanceEmergency: ambEmergency,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Center(
                      child: Text(
                        '0m ──────────────────── 100m ──────────────────── 200m ──────────────────── 300m',
                        style: TextStyle(color: Colors.white38, fontSize: 11, fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Telemetry & Proximity Evaluation Table
            Card(
              color: const Color(0xFF1C2541),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Colors.white12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'REAL-TIME VEHICLE TELEMETRY & 100-FT RULE STATUS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingTextStyle: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        dataTextStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                        columns: const [
                          DataColumn(label: Text('Vehicle ID')),
                          DataColumn(label: Text('Type')),
                          DataColumn(label: Text('Distance (m)')),
                          DataColumn(label: Text('Distance (ft)')),
                          DataColumn(label: Text('Threshold (30.48m)')),
                          DataColumn(label: Text('Alert State')),
                        ],
                        rows: [
                          if (amb != null)
                            DataRow(
                              cells: [
                                DataCell(Text(amb.id, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
                                const DataCell(Text('AMBULANCE')),
                                const DataCell(Text('0.0 m')),
                                const DataCell(Text('0 ft')),
                                const DataCell(Text('SOURCE')),
                                DataCell(
                                  Text(
                                    ambEmergency ? 'BROADCASTING' : 'MUTED',
                                    style: TextStyle(
                                      color: ambEmergency ? Colors.redAccent : Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ...alerts.map((alert) {
                            final insideThreshold = alert.distanceMeters <= kProximityThresholdMeters;
                            return DataRow(
                              cells: [
                                DataCell(Text(alert.vehicleId, style: const TextStyle(fontWeight: FontWeight.bold))),
                                const DataCell(Text('CIVILIAN')),
                                DataCell(Text('${alert.distanceMeters.toStringAsFixed(1)} m')),
                                DataCell(Text('${alert.distanceFeet.toStringAsFixed(0)} ft')),
                                DataCell(
                                  Text(
                                    insideThreshold ? 'WITHIN 100 FT' : 'OUTSIDE 100 FT',
                                    style: TextStyle(
                                      color: insideThreshold ? Colors.amberAccent : Colors.white60,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: alert.isAlertActive
                                          ? Colors.red.withValues(alpha: 0.3)
                                          : Colors.green.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: alert.isAlertActive ? Colors.redAccent : Colors.greenAccent,
                                      ),
                                    ),
                                    child: Text(
                                      alert.isAlertActive ? 'ACTIVE ALERT' : 'CLEAR',
                                      style: TextStyle(
                                        color: alert.isAlertActive ? Colors.redAccent : Colors.greenAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RoadCorridorPainter extends CustomPainter {
  final List<VehicleModel> vehicles;
  final List<AlertStateModel> alerts;
  final bool ambulanceEmergency;

  RoadCorridorPainter({
    required this.vehicles,
    required this.alerts,
    required this.ambulanceEmergency,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const totalCorridorMeters = 300.0;
    final roadTop = size.height * 0.3;
    final roadHeight = size.height * 0.4;
    final roadRect = Rect.fromLTWH(0, roadTop, size.width, roadHeight);

    // 1. Draw Asphalt Road
    final roadPaint = Paint()..color = const Color(0xFF222831);
    canvas.drawRRect(RRect.fromRectAndRadius(roadRect, const Radius.circular(8)), roadPaint);

    // 2. Draw Lane Divider Dashes
    final dashPaint = Paint()
      ..color = Colors.amber.shade400.withValues(alpha: 0.6)
      ..strokeWidth = 2.0;
    final centerY = roadTop + roadHeight / 2.0;
    for (double x = 0; x < size.width; x += 24) {
      canvas.drawLine(Offset(x, centerY), Offset(x + 12, centerY), dashPaint);
    }

    // 3. Coordinate conversion helper: longitude offset from base
    double xForMeters(double meters) {
      return (meters / totalCorridorMeters) * size.width;
    }

    // 4. Draw Ambulance and 30.48m Bubble
    final amb = vehicles.where((v) => v.type == VehicleTypeEnum.ambulance).firstOrNull;
    if (amb != null) {
      // Approximate meters along corridor based on longitude offset
      final dLon = amb.coordinates.longitude - 77.5945627;
      final meters = dLon * 111139.0 * 0.97448; // cosine of 12.97 deg
      final clampedMeters = meters.clamp(0.0, totalCorridorMeters);
      final ambX = xForMeters(clampedMeters);
      final ambY = centerY;

      if (ambulanceEmergency) {
        // Proximity radius (30.48m in canvas pixels)
        final radiusPx = (kProximityThresholdMeters / totalCorridorMeters) * size.width;

        final bubbleFill = Paint()
          ..color = Colors.red.withValues(alpha: 0.18)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(ambX, ambY), radiusPx, bubbleFill);

        final bubbleStroke = Paint()
          ..color = Colors.redAccent
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(Offset(ambX, ambY), radiusPx, bubbleStroke);
      }

      // Draw Ambulance Icon marker
      final ambMarker = Paint()..color = Colors.redAccent;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(ambX, ambY), width: 28, height: 18),
          const Radius.circular(4),
        ),
        ambMarker,
      );

      // Red cross on ambulance
      final crossPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2.0;
      canvas.drawLine(Offset(ambX - 4, ambY), Offset(ambX + 4, ambY), crossPaint);
      canvas.drawLine(Offset(ambX, ambY - 4), Offset(ambX, ambY + 4), crossPaint);
    }

    // 5. Draw Civilian Cars
    for (final v in vehicles.where((v) => v.type == VehicleTypeEnum.civilian)) {
      final dLon = v.coordinates.longitude - 77.5945627;
      final meters = dLon * 111139.0 * 0.97448;
      final clampedMeters = meters.clamp(0.0, totalCorridorMeters);
      final carX = xForMeters(clampedMeters);
      final carY = centerY;

      // Find if this car is alerted
      final alert = alerts.where((a) => a.vehicleId == v.id).firstOrNull;
      final isAlerted = alert?.isAlertActive ?? false;

      final carColor = isAlerted ? Colors.amberAccent : Colors.lightBlueAccent;
      final carPaint = Paint()..color = carColor;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(carX, carY), width: 22, height: 14),
          const Radius.circular(4),
        ),
        carPaint,
      );

      // Draw label
      final textPainter = TextPainter(
        text: TextSpan(
          text: v.id,
          style: TextStyle(
            color: isAlerted ? Colors.redAccent : Colors.white70,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(carX - textPainter.width / 2, carY - 20));
    }
  }

  @override
  bool shouldRepaint(covariant RoadCorridorPainter oldDelegate) => true;
}
