import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/alert.dart';
import '../models/incubator_config.dart';
import '../models/schedule.dart';
import '../models/sensor_data.dart';

class IncubatorService extends ChangeNotifier {
  // Base URL is not used for direct connection, we use the IP (incubatorId)

  String? _currentIncubatorId; // This is now the IP Address
  SensorData? _latestSensorData;
  IncubatorConfig? _config;
  List<Alert> _alerts = [];
  bool _isLoading = false;

  String? get currentIncubatorId => _currentIncubatorId;
  SensorData? get latestSensorData => _latestSensorData;
  IncubatorConfig? get config => _config;
  List<Alert> get alerts => _alerts;
  bool get isLoading => _isLoading;
  bool get isConnected => true; // Assume connected if IP is set

  Future<void> setIncubator(String ipAddress) async {
    _currentIncubatorId = ipAddress;
    await Future.wait([loadConfig(ipAddress), loadAlerts(ipAddress)]);
    notifyListeners();
  }

  Future<void> loadConfig(String ip) async {
    try {
      final response = await http.get(Uri.parse('http://$ip/api/config'));
      if (response.statusCode == 200) {
        _config = IncubatorConfig.fromJson(json.decode(response.body));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading config: $e');
    }
  }

  Future<void> updateConfig(String ip, IncubatorConfig config) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await http.post(
        // Firmware uses POST for config update
        Uri.parse('http://$ip/api/config'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(config.toJson()),
      );

      if (response.statusCode == 200) {
        // Refresh config to confirm
        loadConfig(ip);
      }
    } catch (e) {
      debugPrint('Error updating config: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> getHistory(
    String ip,
    DateTime startDate,
    DateTime endDate, {
    String resolution = '5min',
  }) async {
    try {
      final response = await http.get(Uri.parse('http://$ip/api/history'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
    }
    return [];
  }

  Future<void> loadAlerts(String ip) async {
    // Firmware doesn't have alerts API yet, stubbing
    _alerts = [];
    notifyListeners();
  }

  Future<Map<String, dynamic>?> getHatchPrediction(String ip) async {
    try {
      final response = await http.get(Uri.parse('http://$ip/api/analytics'));

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

  // Manual Control Stubs - Implemented via API
  Future<void> setSystemMode(int mode) async {
    await _sendControlCommand({'mode': mode});
  }

  Future<void> turnEggs() async {
    await _sendControlCommand({'turnEggs': true});
  }

  Future<void> toggleFan(bool on) async {
    await _sendControlCommand({'fan': on});
  }

  Future<void> toggleHeater(bool on) async {
    await _sendControlCommand({'heater': on});
  }

  Future<void> toggleHumidifier(bool on) async {
    await _sendControlCommand({'humidifier': on});
  }

  Future<void> _sendControlCommand(Map<String, dynamic> command) async {
    if (_currentIncubatorId == null) return;
    try {
      await http.post(
        Uri.parse('http://$_currentIncubatorId/api/control'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(command),
      );
    } catch (e) {
      debugPrint("Control Error: $e");
    }
  }

  // --- Schedule API ---

  Future<List<Schedule>> getSchedules(String ip) async {
    try {
      final response = await http.get(Uri.parse('http://$ip/api/schedule'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => Schedule.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error loading schedules: $e');
    }
    return [];
  }

  Future<void> addSchedule(String ip, Schedule schedule) async {
    try {
      await http.post(
        Uri.parse('http://$ip/api/schedule'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(schedule.toJson()),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding schedule: $e');
    }
  }

  Future<void> deleteSchedule(String ip, int id) async {
    try {
      // API expects DELETE with query param id
      await http.delete(Uri.parse('http://$ip/api/schedule?id=$id'));
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting schedule: $e');
    }
  }

  // --- Time Sync ---

  Future<void> syncTime(String ip) async {
    try {
      final now = DateTime.now();
      // ESP32 usually expects UTC epoch, but if no timezone management, maybe local?
      // Let's send local epoch if we want it to match phone exactly without TZ math on MCU.
      // Actually, safest is to send what the phone shows.
      final epoch = now.millisecondsSinceEpoch ~/ 1000;

      await http.post(
        Uri.parse('http://$ip/api/time'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'epoch': epoch}),
      );
      debugPrint("Time synced to: $now");
    } catch (e) {
      debugPrint('Error syncing time: $e');
    }
  }
}
