import 'dart:math' as math;

/// 100 feet in metres
const double kProximityThresholdMeters = 30.48;
const double kFeetPerMeter = 3.28084;
const double kEarthRadiusMeters = 6371000.0;
const String kWarningMessage = "AMBULANCE APPROACHING — MAKE WAY WHEN SAFE";

/// Calculate great-circle distance in metres between two coordinates
double haversineDistanceMeters(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  final dLat = (lat2 - lat1) * (math.pi / 180.0);
  final dLon = (lon2 - lon1) * (math.pi / 180.0);
  final rLat1 = lat1 * (math.pi / 180.0);
  final rLat2 = lat2 * (math.pi / 180.0);

  final a = math.sin(dLat / 2.0) * math.sin(dLat / 2.0) +
      math.cos(rLat1) *
          math.cos(rLat2) *
          math.sin(dLon / 2.0) *
          math.sin(dLon / 2.0);
  final clampedA = math.min(1.0, math.max(0.0, a));
  final c = 2.0 * math.atan2(math.sqrt(clampedA), math.sqrt(1.0 - clampedA));
  return kEarthRadiusMeters * c;
}

class AlertStateModel {
  final String alertId;
  final String vehicleId;
  final String ambulanceId;
  final double distanceMeters;
  final double distanceFeet;
  final bool isAlertActive;
  final String message;
  final double timestamp;

  const AlertStateModel({
    required this.alertId,
    required this.vehicleId,
    required this.ambulanceId,
    required this.distanceMeters,
    required this.distanceFeet,
    required this.isAlertActive,
    required this.message,
    required this.timestamp,
  });

  factory AlertStateModel.fromJson(Map<String, dynamic> json) {
    return AlertStateModel(
      alertId: json['alert_id'] as String? ?? '',
      vehicleId: json['vehicle_id'] as String? ?? '',
      ambulanceId: json['ambulance_id'] as String? ?? '',
      distanceMeters: (json['distance_meters'] as num?)?.toDouble() ?? 0.0,
      distanceFeet: (json['distance_feet'] as num?)?.toDouble() ?? 0.0,
      isAlertActive: json['is_alert_active'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      timestamp: (json['timestamp'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Create a safe fallback inactive state
  factory AlertStateModel.clear({String vehicleId = 'CAR-01'}) {
    return AlertStateModel(
      alertId: 'IDLE',
      vehicleId: vehicleId,
      ambulanceId: '',
      distanceMeters: 999.0,
      distanceFeet: 999.0 * kFeetPerMeter,
      isAlertActive: false,
      message: 'No active emergency within proximity.',
      timestamp: DateTime.now().millisecondsSinceEpoch / 1000.0,
    );
  }
}
