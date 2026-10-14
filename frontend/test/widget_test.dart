import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clearpath_frontend/main.dart';
import 'package:clearpath_frontend/models/alert_state.dart';
import 'package:clearpath_frontend/widgets/alert_banner.dart';
import 'package:clearpath_frontend/services/websocket_service.dart';

void main() {
  test('Haversine distance calculation in Dart satisfies 30.48m threshold', () {
    // Exactly same point -> 0 meters
    final zeroDist = haversineDistanceMeters(12.971598, 77.594562, 12.971598, 77.594562);
    expect(zeroDist, 0.0);

    // 20 metres north: ~20 / 111139.0 degrees lat
    final dist20m = haversineDistanceMeters(
      12.971598,
      77.594562,
      12.971598 + (20.0 / 111139.0),
      77.594562,
    );
    expect(dist20m, lessThanOrEqualTo(kProximityThresholdMeters));

    // 50 metres north: ~50 / 111139.0 degrees lat
    final dist50m = haversineDistanceMeters(
      12.971598,
      77.594562,
      12.971598 + (50.0 / 111139.0),
      77.594562,
    );
    expect(dist50m, greaterThan(kProximityThresholdMeters));
  });

  testWidgets('ClearPathApp renders HomeScreen and mode selection cards', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ClearPathApp());
    await tester.pump();

    // Verify Title & Modes
    expect(find.text('ClearPath'), findsOneWidget);
    expect(find.text('Ambulance Mode'), findsOneWidget);
    expect(find.text('Driver Mode'), findsOneWidget);
    expect(find.text('Interactive Road Simulation'), findsOneWidget);

    // Cancel pending singleton timers
    WebSocketService().disconnect();
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('AlertBanner displays high-priority warning when alert is active', (
    WidgetTester tester,
  ) async {
    const activeAlert = AlertStateModel(
      alertId: 'ALT-01',
      vehicleId: 'CAR-01',
      ambulanceId: 'AMB-01',
      distanceMeters: 22.5,
      distanceFeet: 73.8,
      isAlertActive: true,
      message: kWarningMessage,
      timestamp: 1700000000.0,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AlertBanner(alert: activeAlert),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.text('AMBULANCE APPROACHING — MAKE WAY WHEN SAFE'),
      findsOneWidget,
    );
    expect(
      find.text('Estimated Proximity: 22.5 m  (74 ft)'),
      findsOneWidget,
    );
  });

  testWidgets('AlertBanner displays clear state when alert is inactive', (
    WidgetTester tester,
  ) async {
    final clearAlert = AlertStateModel.clear();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AlertBanner(alert: clearAlert),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.text('CLEAR ROADWAY — NO NEARBY AMBULANCE'),
      findsOneWidget,
    );
    expect(
      find.text('AMBULANCE APPROACHING — MAKE WAY WHEN SAFE'),
      findsNothing,
    );
  });
}
