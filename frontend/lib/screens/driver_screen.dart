import 'package:flutter/material.dart';
import '../models/alert_state.dart';
import '../services/websocket_service.dart';
import '../widgets/alert_banner.dart';
import '../widgets/connection_badge.dart';
import '../widgets/safety_disclaimer.dart';

class DriverScreen extends StatefulWidget {
  const DriverScreen({super.key});

  @override
  State<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {
  final WebSocketService _wsService = WebSocketService();
  String _selectedVehicleId = 'CAR-01';

  @override
  void initState() {
    super.initState();
    _wsService.addListener(_onServiceUpdate);
    // Re-connect with driver identity
    _wsService.connect(clientType: 'DRIVER', vehicleId: _selectedVehicleId);
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
    // Locate alert for the selected civilian vehicle
    final alert = _wsService.alerts.where((a) => a.vehicleId == _selectedVehicleId).firstOrNull ??
        AlertStateModel.clear(vehicleId: _selectedVehicleId);

    // Locate vehicle details
    final myVehicle = _wsService.vehicles.where((v) => v.id == _selectedVehicleId).firstOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Driver Mode'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ConnectionBadge(
              status: _wsService.status,
              onRetry: () => _wsService.connect(
                clientType: 'DRIVER',
                vehicleId: _selectedVehicleId,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vehicle switcher selector
            Row(
              children: [
                const Text(
                  'My Vehicle:',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _selectedVehicleId,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  underline: Container(height: 2, color: Colors.blueAccent),
                  items: const [
                    DropdownMenuItem(value: 'CAR-01', child: Text('CAR-01 (Civic Sedan @ 60m)')),
                    DropdownMenuItem(value: 'CAR-02', child: Text('CAR-02 (Delivery Van @ 130m)')),
                    DropdownMenuItem(value: 'CAR-03', child: Text('CAR-03 (EV Hatchback @ 210m)')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedVehicleId = val);
                      _wsService.connect(clientType: 'DRIVER', vehicleId: val);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Connection or error warning if offline
            if (_wsService.status != WsConnectionStatus.connected) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade900.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade700),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _wsService.status == WsConnectionStatus.connecting
                            ? 'Connecting to ClearPath proximity alert network...'
                            : 'Backend server disconnected. Please make sure FastAPI backend is running.',
                        style: const TextStyle(color: Colors.orangeAccent, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Prominent Alert Banner (Switches between Calm Green and High-Priority Crimson Alert)
            AlertBanner(alert: alert, fullScreenMode: alert.isAlertActive),
            const SizedBox(height: 24),

            // Radar & Distance Telemetry Card
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'PROXIMITY RADAR STATUS',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: alert.isAlertActive
                                ? Colors.red.withValues(alpha: 0.2)
                                : Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: alert.isAlertActive ? Colors.redAccent : Colors.greenAccent,
                            ),
                          ),
                          child: Text(
                            alert.isAlertActive ? 'ALERT TRIGGERED' : 'CLEAR',
                            style: TextStyle(
                              color: alert.isAlertActive ? Colors.redAccent : Colors.greenAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildMetricRow(
                      'Distance to Nearest Ambulance',
                      alert.distanceMeters < 900
                          ? '${alert.distanceMeters.toStringAsFixed(1)} m  (${alert.distanceFeet.toStringAsFixed(0)} ft)'
                          : 'Out of range (>300m)',
                      highlight: alert.isAlertActive,
                    ),
                    _buildMetricRow(
                      'Proximity Threshold',
                      '30.48 m  (100.0 ft)',
                    ),
                    _buildMetricRow(
                      'Ambulance Emergency Status',
                      _wsService.ambulanceEmergencyActive ? 'ACTIVE (SIREN ON)' : 'INACTIVE',
                      textColor: _wsService.ambulanceEmergencyActive ? Colors.redAccent : Colors.greenAccent,
                    ),
                    if (myVehicle != null) ...[
                      _buildMetricRow(
                        'Vehicle Position',
                        '${myVehicle.coordinates.latitude.toStringAsFixed(6)}, ${myVehicle.coordinates.longitude.toStringAsFixed(6)}',
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Safety notice
            const SafetyDisclaimerBanner(compact: true),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, {bool highlight = false, Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          Text(
            value,
            style: TextStyle(
              color: textColor ?? (highlight ? Colors.redAccent : Colors.white),
              fontWeight: FontWeight.bold,
              fontSize: 13,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
