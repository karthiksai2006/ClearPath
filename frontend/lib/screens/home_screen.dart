import 'package:flutter/material.dart';
import '../services/websocket_service.dart';
import '../widgets/connection_badge.dart';
import '../widgets/safety_disclaimer.dart';
import 'ambulance_screen.dart';
import 'driver_screen.dart';
import 'simulation_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WebSocketService _wsService = WebSocketService();

  @override
  void initState() {
    super.initState();
    _wsService.addListener(_onWsUpdate);
    // Connect to local backend
    _wsService.connect();
  }

  void _onWsUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _wsService.removeListener(_onWsUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.shade700,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.emergency, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'ClearPath',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('MVP', style: TextStyle(fontSize: 10, color: Colors.white70)),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: ConnectionBadge(
                status: _wsService.status,
                onRetry: () => _wsService.connect(),
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
            // Welcome Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ambulance Proximity Alert System',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Instant 100-foot (30.48-metre) emergency vehicle awareness for connected civilian drivers, enabling safe right-of-way clearance.',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade300, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Safety notice
            const SafetyDisclaimerBanner(),
            const SizedBox(height: 24),

            const Text(
              'SELECT OPERATIONAL MODE',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 14),

            // Mode 1: Ambulance Mode
            _buildModeCard(
              context,
              title: 'Ambulance Mode',
              subtitle: 'Emergency responder interface to start and stop authenticated location broadcasts.',
              badgeText: 'DISPATCHER / VEHICLE',
              icon: Icons.local_hospital_rounded,
              color: Colors.redAccent,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AmbulanceScreen()),
                );
              },
            ),
            const SizedBox(height: 14),

            // Mode 2: Driver Mode
            _buildModeCard(
              context,
              title: 'Driver Mode',
              subtitle: 'Participating civilian dashboard with automatic 100-foot warning screen.',
              badgeText: 'CIVILIAN VEHICLE',
              icon: Icons.directions_car_filled_rounded,
              color: Colors.blueAccent,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DriverScreen()),
                );
              },
            ),
            const SizedBox(height: 14),

            // Mode 3: Road Simulation
            _buildModeCard(
              context,
              title: 'Interactive Road Simulation',
              subtitle: 'Visual corridor showing an ambulance and 3 cars demonstrating 100ft activation and deactivation.',
              badgeText: 'DEMONSTRATION & TEST',
              icon: Icons.alt_route_rounded,
              color: Colors.tealAccent,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SimulationScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String badgeText,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.35)),
      ),
      color: const Color(0xFF1E222D),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.5)),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.3),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
