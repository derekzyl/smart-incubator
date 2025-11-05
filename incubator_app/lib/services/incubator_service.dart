import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/sensor_data.dart';
import '../models/incubator_config.dart';
import '../models/alert.dart';

class IncubatorService extends ChangeNotifier {
  static const String baseUrl = 'http://localhost:8000/api/v1';
  
  String? _currentIncubatorId;
  SensorData? _latestSensorData;
  IncubatorConfig? _config;
  List<Alert> _alerts = [];
  bool _isLoading = false;

  String? get currentIncubatorId => _currentIncubatorId;
  SensorData? get latestSensorData => _latestSensorData;
  IncubatorConfig? get config => _config;
  List<Alert> get alerts => _alerts;
  bool get isLoading => _isLoading;

  Future<void> setIncubator(String incubatorId) async {
    _currentIncubatorId = incubatorId;
    await Future.wait([
      loadConfig(incubatorId),
      loadAlerts(incubatorId),
    ]);
    notifyListeners();
  }

  Future<void> loadConfig(String incubatorId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/incubator/$incubatorId'),
      );
      if (response.statusCode == 200) {
        _config = IncubatorConfig.fromJson(json.decode(response.body));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading config: $e');
    }
  }

  Future<void> updateConfig(String incubatorId, IncubatorConfig config) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final response = await http.put(
        Uri.parse('$baseUrl/incubator/$incubatorId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(config.toJson()),
      );
      
      if (response.statusCode == 200) {
        _config = IncubatorConfig.fromJson(json.decode(response.body));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating config: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> getHistory(
    String incubatorId,
    DateTime startDate,
    DateTime endDate, {
    String resolution = '5min',
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/sensors/history/$incubatorId').replace(
          queryParameters: {
            'start_date': startDate.toIso8601String(),
            'end_date': endDate.toIso8601String(),
            'resolution': resolution,
          },
        ),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
    }
    return [];
  }

  Future<void> loadAlerts(String incubatorId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/alerts/$incubatorId').replace(
          queryParameters: {'resolved': 'false'},
        ),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _alerts = (data['alerts'] as List)
            .map((json) => Alert.fromJson(json))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading alerts: $e');
    }
  }

  Future<Map<String, dynamic>?> getHatchPrediction(String incubatorId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/analytics/hatch-prediction/$incubatorId'),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint('Error loading prediction: $e');
    }
    return null;
  }

  void updateSensorData(SensorData data) {
    _latestSensorData = data;
    notifyListeners();
  }

  void addAlert(Alert alert) {
    _alerts.insert(0, alert);
    notifyListeners();
  }
}

