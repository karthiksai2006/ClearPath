import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../services/websocket_service.dart';
import '../widgets/connection_badge.dart';
import '../widgets/safety_disclaimer.dart';

class AmbulanceScreen extends StatefulWidget {
  const AmbulanceScreen({super.key});

  @override
  State<AmbulanceScreen> createState() => _AmbulanceScreenState();
}

class _AmbulanceScreenState extends State<AmbulanceScreen> {
  final WebSocketService _wsService = WebSocketService();
  final TextEditingController _passcodeController = TextEditingController(
    text: 'CLEARPATH-EMERGENCY-2026',
  );
  bool _isSubmitting = false;

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
    _passcodeController.dispose();
    super.dispose();
  }

  Future<void> _handleStartEmergency() async {
    final passcode = _passcodeController.text.trim();
    if (passcode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter authorization passcode.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final success = await _wsService.startAmbulanceEmergency('AMB-01', passcode);
    setState(() => _isSubmitting = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Emergency Mode Activated! Broadcasting location.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.deepOrange,
            content: Text('Authorization Failed: Invalid passcode.'),
          ),
        );
      }
    }
  }

  Future<void> _handleStopEmergency() async {
    setState(() => _isSubmitting = true);
    final success = await _wsService.stopAmbulanceEmergency('AMB-01');
    setState(() => _isSubmitting = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Emergency Mode Stopped. Proximity alerts cleared.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEmergency = _wsService.ambulanceEmergencyActive;
    final amb = _wsService.vehicles
        .where((v) => v.type == VehicleTypeEnum.ambulance)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ambulance Dispatcher Mode'),
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
            const SizedBox(height: 20),

            // Emergency Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isEmergency ? const Color(0xFF5A1212) : const Color(0xFF1E222D),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isEmergency ? Colors.redAccent : Colors.white12,
                  width: isEmergency ? 2.5 : 1,
                ),
                boxShadow: isEmergency
                    ? [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isEmergency ? Colors.red : Colors.grey.shade800,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isEmergency ? Icons.warning_rounded : Icons.local_hospital_outlined,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    isEmergency ? 'EMERGENCY BROADCAST ACTIVE' : 'EMERGENCY BROADCAST STANDBY',
                    style: TextStyle(
                      color: isEmergency ? Colors.white : Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isEmergency
                        ? 'Broadcasting coordinates. Civilian vehicles within 30.48m (100ft) receive proximity alert.'
                        : 'Emergency mode is inactive. No proximity alerts are sent.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  if (isEmergency) ...[
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red.shade900,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSubmitting ? null : _handleStopEmergency,
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: Text(
                        _isSubmitting ? 'STOPPING...' : 'STOP EMERGENCY SESSION',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ] else ...[
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSubmitting ? null : _handleStartEmergency,
                      icon: const Icon(Icons.play_circle_filled_rounded),
                      label: Text(
                        _isSubmitting ? 'STARTING...' : 'START EMERGENCY MODE',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Passcode Security Section
            Card(
              color: const Color(0xFF1E222D),
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
                      children: [
                        const Icon(Icons.security, color: Colors.amberAccent, size: 20),
                        const SizedBox(width: 10),
                        const Text(
                          'SECURITY & DISPATCH AUTHENTICATION',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'To prevent fake ambulance broadcasts, ClearPath requires an authorized dispatcher passcode before activating emergency broadcasts.',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _passcodeController,
                      enabled: !isEmergency,
                      decoration: InputDecoration(
                        labelText: 'Dispatcher Passcode',
                        hintText: 'e.g. CLEARPATH-EMERGENCY-2026',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.key),
                      ),
                    ),
                    if (_wsService.ambulanceSessionToken != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Session Token: ${_wsService.ambulanceSessionToken}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.greenAccent,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Telemetry coordinates card
            Card(
              color: const Color(0xFF1E222D),
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
                      'AMBULANCE TELEMETRY',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (amb != null) ...[
                      _buildTelemetryRow('Ambulance ID', amb.id),
                      _buildTelemetryRow('Latitude', amb.coordinates.latitude.toStringAsFixed(6)),
                      _buildTelemetryRow('Longitude', amb.coordinates.longitude.toStringAsFixed(6)),
                      _buildTelemetryRow('Speed', '${(amb.coordinates.speedMps * 3.6).toStringAsFixed(1)} km/h'),
                      _buildTelemetryRow('Heading', '${amb.coordinates.headingDegrees.toStringAsFixed(0)}° East'),
                    ] else ...[
                      const Text(
                        'Waiting for simulation telemetry feed...',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
