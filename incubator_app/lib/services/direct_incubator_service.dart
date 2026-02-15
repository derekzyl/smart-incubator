import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/alert.dart';
import '../models/incubator_config.dart';
import '../models/schedule.dart';
import '../models/sensor_data.dart';
import '../services/incubator_service.dart';

class DirectIncubatorService extends IncubatorService {
  String _baseUrl = 'http://192.168.4.1'; // Default AP IP or placeholder
  final bool _isLoading = false;
  SensorData? _latestSensorData;
  IncubatorConfig? _deviceConfig;
  Timer? _pollingTimer;
  bool _isConnected = false;

  // Overrides to serve data from local source
  @override
  String? get currentIncubatorId => 'esp32_device';
  @override
  SensorData? get latestSensorData => _latestSensorData;
  @override
  IncubatorConfig? get config => _deviceConfig;
  @override
  List<Alert> get alerts => [];
  @override
  bool get isLoading => _isLoading;

  @override
  bool get isConnected => _isConnected;
  String get baseUrl => _baseUrl;

  DirectIncubatorService() {
    _loadSavedIp();
  }

  Future<void> _loadSavedIp() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIp = prefs.getString('incubator_ip');
    if (savedIp != null && savedIp.isNotEmpty) {
      _baseUrl = 'http://$savedIp';
    }
    _startPolling();
  }

  Future<void> setIpAddress(String ip) async {
    _baseUrl = 'http://$ip';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('incubator_ip', ip);
    notifyListeners();
    // Restart polling or trigger immediate fetch
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      fetchStatus();
    });
    fetchStatus(); // Immediate fetch
  }

  Future<void> fetchStatus() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/status'))
          .timeout(const Duration(seconds: 5)); // Increased timeout

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _mapSensorData(data);
        _isConnected = true;
      } else {
        debugPrint('Connection failed: ${response.statusCode}');
        _isConnected = false;
      }
    } catch (e) {
      // debugPrint('Error fetching status: $e'); // Make this more visible if possible, or just log
      print(
        'DirectConnection Error: $e',
      ); // using print for visibility in some consoles
      _isConnected = false;
    }
    notifyListeners();
  }

  void _mapSensorData(Map<String, dynamic> data) {
    // Firmware JSON: {temp, humid, fan, heater, humidifier, stepperPos, time}
    final temp = (data['temp'] as num?)?.toDouble() ?? 0.0;
    final humid = (data['humid'] as num?)?.toDouble() ?? 0.0;

    _latestSensorData = SensorData(
      incubatorId: 'esp32_device',
      temp1: temp,
      temp2: temp, // Duplicate for now
      tempSht31: temp, // Duplicate
      humiditySht31: humid,
      heaterState: data['heater'] ?? false,
      humidifierState: data['humidifier'] ?? false,
      fanSpeed: (data['fan'] ?? false) ? 100 : 0, // Map bool to int speed
      systemMode: data['mode'] ?? 0, // Default to 0 (Auto)
      timestamp: DateTime.now(),
    );
  }

  // Control Methods
  Future<void> setSystemMode(int mode) async => _sendCommand({'mode': mode});
  Future<void> turnEggs() async => _sendCommand({'turnEggs': true});

  Future<void> toggleFan(bool on) async => _sendCommand({'fan': on});
  Future<void> toggleHeater(bool on) async => _sendCommand({'heater': on});
  Future<void> toggleHumidifier(bool on) async =>
      _sendCommand({'humidifier': on});

  Future<void> _sendCommand(Map<String, dynamic> command) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/api/control'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(command),
      );
      // Fetch status immediately to update UI
      await Future.delayed(
        const Duration(milliseconds: 100),
      ); // Small delay for processing
      fetchStatus();
    } catch (e) {
      debugPrint('Error sending command: $e');
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  // Config sync with device
  @override
  Future<void> setIncubator(String id) async {}

  @override
  Future<void> loadConfig(String id) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/config'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        _deviceConfig = IncubatorConfig.fromDeviceJson(data);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading config: $e');
    }
  }

  @override
  Future<void> updateConfig(String id, IncubatorConfig config) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/config'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(config.toJson()),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        await loadConfig(id);
        notifyListeners();
      } else {
        debugPrint('Config update failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error updating config: $e');
      rethrow;
    }
  }
  // Schedule API - use baseUrl (device IP) instead of currentIncubatorId
  @override
  Future<List<Schedule>> getSchedules(String id) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/schedule'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => Schedule.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error loading schedules: $e');
    }
    return [];
  }

  @override
  Future<void> addSchedule(String id, Schedule schedule) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/schedule'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(schedule.toJson()),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        notifyListeners();
      } else {
        debugPrint('Add schedule failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error adding schedule: $e');
    }
  }

  @override
  Future<void> deleteSchedule(String id, int scheduleId) async {
    try {
      final response = await http
          .delete(Uri.parse('$_baseUrl/api/schedule?id=$scheduleId'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        notifyListeners();
      } else {
        debugPrint('Delete schedule failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error deleting schedule: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getHistory(
    String id,
    DateTime start,
    DateTime end, {
    String resolution = '5min',
  }) async => [];
  @override
  Future<void> loadAlerts(String id) async {}
  @override
  Future<Map<String, dynamic>?> getHatchPrediction(String id) async => null;
}
