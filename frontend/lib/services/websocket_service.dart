import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/alert_state.dart';
import '../models/vehicle.dart';

enum WsConnectionStatus { connecting, connected, disconnected, error }

class WebSocketService extends ChangeNotifier {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;

  WsConnectionStatus _status = WsConnectionStatus.disconnected;
  WsConnectionStatus get status => _status;

  String _backendHost = '127.0.0.1:8000';
  String get backendHost => _backendHost;

  List<VehicleModel> _vehicles = [];
  List<VehicleModel> get vehicles => _vehicles;

  List<AlertStateModel> _alerts = [];
  List<AlertStateModel> get alerts => _alerts;

  bool _isSimulationRunning = false;
  bool get isSimulationRunning => _isSimulationRunning;

  int _stepCount = 0;
  int get stepCount => _stepCount;

  String? _ambulanceSessionToken;
  String? get ambulanceSessionToken => _ambulanceSessionToken;

  bool _ambulanceEmergencyActive = false;
  bool get ambulanceEmergencyActive => _ambulanceEmergencyActive;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void updateBackendHost(String host) {
    if (_backendHost != host) {
      _backendHost = host;
      connect();
    }
  }

  bool _isManuallyDisconnected = false;

  void connect({String clientType = 'GENERIC', String vehicleId = ''}) {
    _isManuallyDisconnected = false;
    _status = WsConnectionStatus.connecting;
    _errorMessage = null;
    notifyListeners();

    _cleanup();

    try {
      final wsUrl = Uri.parse(
        'ws://$_backendHost/ws/telemetry?client_type=$clientType&vehicle_id=$vehicleId',
      );
      _channel = WebSocketChannel.connect(wsUrl);

      _channel!.stream.listen(
        (dynamic rawMessage) {
          if (_status != WsConnectionStatus.connected) {
            _status = WsConnectionStatus.connected;
            _errorMessage = null;
            notifyListeners();
          }
          _handleMessage(rawMessage.toString());
        },
        onDone: () {
          _status = WsConnectionStatus.disconnected;
          notifyListeners();
          if (!_isManuallyDisconnected) {
            _scheduleReconnect();
          }
        },
        onError: (dynamic error) {
          _status = WsConnectionStatus.error;
          _errorMessage = error.toString();
          notifyListeners();
          if (!_isManuallyDisconnected) {
            _scheduleReconnect();
          }
        },
      );

      _startHeartbeat();
    } catch (e) {
      _status = WsConnectionStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      if (!_isManuallyDisconnected) {
        _scheduleReconnect();
      }
    }
  }

  void _handleMessage(String rawJson) {
    try {
      final data = jsonDecode(rawJson) as Map<String, dynamic>;
      final type = data['type'] as String?;

      if (type == 'SIMULATION_STATE') {
        final payload = data['data'] as Map<String, dynamic>;
        _isSimulationRunning = payload['is_running'] as bool? ?? false;
        _stepCount = (payload['step_count'] as num?)?.toInt() ?? 0;

        final rawVehicles = payload['vehicles'] as List<dynamic>? ?? [];
        _vehicles = rawVehicles
            .map((v) => VehicleModel.fromJson(v as Map<String, dynamic>))
            .toList();

        final rawAlerts = payload['active_alerts'] as List<dynamic>? ?? [];
        _alerts = rawAlerts
            .map((a) => AlertStateModel.fromJson(a as Map<String, dynamic>))
            .toList();

        // Check if AMB-01 is in emergency mode
        final amb = _vehicles.where((v) => v.type == VehicleTypeEnum.ambulance).firstOrNull;
        if (amb != null) {
          _ambulanceEmergencyActive = amb.emergencyActive;
        }

        notifyListeners();
      } else if (type == 'PROXIMITY_ALERT') {
        final alert = AlertStateModel.fromJson(
          data['data'] as Map<String, dynamic>,
        );
        final index = _alerts.indexWhere((a) => a.vehicleId == alert.vehicleId);
        if (index >= 0) {
          _alerts[index] = alert;
        } else {
          _alerts.add(alert);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error parsing WebSocket message: $e');
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_status == WsConnectionStatus.connected && _channel != null) {
        try {
          _channel!.sink.add('ping');
        } catch (_) {}
      }
    });
  }

  void _scheduleReconnect() {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (_status != WsConnectionStatus.connected) {
        connect();
      }
    });
  }

  void _cleanup() {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  void disconnect() {
    _isManuallyDisconnected = true;
    _cleanup();
    _status = WsConnectionStatus.disconnected;
    notifyListeners();
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }

  // --- REST API Callbacks ---

  Future<bool> startAmbulanceEmergency(String ambulanceId, String passcode) async {
    try {
      final res = await http.post(
        Uri.parse('http://$_backendHost/api/ambulance/session/start'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'ambulance_id': ambulanceId,
          'passcode': passcode,
        }),
      );
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        _ambulanceSessionToken = json['session_token'] as String?;
        _ambulanceEmergencyActive = true;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> stopAmbulanceEmergency(String ambulanceId) async {
    if (_ambulanceSessionToken == null) return false;
    try {
      final res = await http.post(
        Uri.parse('http://$_backendHost/api/ambulance/session/stop'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'ambulance_id': ambulanceId,
          'session_token': _ambulanceSessionToken,
        }),
      );
      if (res.statusCode == 200) {
        _ambulanceSessionToken = null;
        _ambulanceEmergencyActive = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleSimulation(bool run) async {
    final endpoint = run ? 'start' : 'pause';
    try {
      await http.post(Uri.parse('http://$_backendHost/api/simulation/$endpoint'));
      _isSimulationRunning = run;
      notifyListeners();
    } catch (e) {
      debugPrint('Simulation toggle error: $e');
    }
  }

  Future<void> stepSimulation() async {
    try {
      await http.post(Uri.parse('http://$_backendHost/api/simulation/step?dt_seconds=1.0'));
    } catch (e) {
      debugPrint('Simulation step error: $e');
    }
  }

  Future<void> resetSimulation() async {
    try {
      await http.post(Uri.parse('http://$_backendHost/api/simulation/reset'));
      _isSimulationRunning = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Simulation reset error: $e');
    }
  }

  Future<void> toggleSimEmergency(bool active) async {
    try {
      await http.post(
        Uri.parse('http://$_backendHost/api/simulation/emergency?active=$active'),
      );
      _ambulanceEmergencyActive = active;
      notifyListeners();
    } catch (e) {
      debugPrint('Simulation emergency toggle error: $e');
    }
  }
}
