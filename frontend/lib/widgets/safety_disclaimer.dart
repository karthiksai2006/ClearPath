import 'package:flutter/material.dart';

class SafetyDisclaimerBanner extends StatelessWidget {
  final bool compact;
  const SafetyDisclaimerBanner({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Semantics(
        label: 'Prototype Boundary: Proximity threshold of 30.48 metres (100 feet) is not proof of lane. Not certified for emergency dispatch.',
        child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.amber.shade900.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.amber.shade700, width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.shield_outlined, size: 16, color: Colors.amber.shade300),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Prototype Only: Proximity threshold (30.48m/100ft) is not proof of lane. Not certified for emergency dispatch.',
                style: TextStyle(
                  color: Colors.amber.shade200,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
      );
    }

    return Card(
      color: const Color(0xFF1E222D),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.amber.shade600.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade600.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.warning_amber_rounded, color: Colors.amber.shade400, size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'SAFETY & PROTOTYPE BOUNDARIES',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.8,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              '• 100-foot (30.48m) rule treats distance as a proximity threshold, not proof of lane.\n'
              '• ClearPath prototype is simulation-only and requires participating devices.\n'
              '• Ordinary apps cannot broadcast to non-participating vehicles or unsupported dashboards.\n'
              '• Never deploy this prototype in real-world life-critical operations.',
              style: TextStyle(fontSize: 12, height: 1.45, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
