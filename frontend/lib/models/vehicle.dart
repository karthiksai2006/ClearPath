/// Models representing vehicles and geographic positions in ClearPath.
library;

class CoordinatesModel {
  final double latitude;
  final double longitude;
  final double speedMps;
  final double headingDegrees;
  final double timestamp;

  const CoordinatesModel({
    required this.latitude,
    required this.longitude,
    this.speedMps = 0.0,
    this.headingDegrees = 0.0,
    this.timestamp = 0.0,
  });

  factory CoordinatesModel.fromJson(Map<String, dynamic> json) {
    return CoordinatesModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      speedMps: (json['speed_mps'] as num?)?.toDouble() ?? 0.0,
      headingDegrees: (json['heading_degrees'] as num?)?.toDouble() ?? 0.0,
      timestamp: (json['timestamp'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'speed_mps': speedMps,
        'heading_degrees': headingDegrees,
        'timestamp': timestamp,
      };
}

enum VehicleTypeEnum { ambulance, civilian }

class VehicleModel {
  final String id;
  final String name;
  final VehicleTypeEnum type;
  final CoordinatesModel coordinates;
  final bool emergencyActive;
  final String? sessionToken;

  const VehicleModel({
    required this.id,
    required this.name,
    required this.type,
    required this.coordinates,
    this.emergencyActive = false,
    this.sessionToken,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: (json['type'] == 'AMBULANCE')
          ? VehicleTypeEnum.ambulance
          : VehicleTypeEnum.civilian,
      coordinates: CoordinatesModel.fromJson(
        json['coordinates'] as Map<String, dynamic>,
      ),
      emergencyActive: json['emergency_active'] as bool? ?? false,
      sessionToken: json['session_token'] as String?,
    );
  }
}
