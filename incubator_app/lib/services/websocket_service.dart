import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/sensor_data.dart';
import '../models/alert.dart';

class WebSocketService extends ChangeNotifier {
  static const String wsBaseUrl = 'ws://localhost:8000/ws/live';
  
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  String? _currentIncubatorId;
  bool _isConnected = false;
  SensorData? _latestSensorData;
  Alert? _latestAlert;

  bool get isConnected => _isConnected;
  SensorData? get latestSensorData => _latestSensorData;
  Alert? get latestAlert => _latestAlert;

  Future<void> connect(String incubatorId) async {
    if (_channel != null && _currentIncubatorId == incubatorId && _isConnected) {
      return; // Already connected to this incubator
    }

    await disconnect();
    _currentIncubatorId = incubatorId;

    try {
      final uri = Uri.parse('$wsBaseUrl/$incubatorId');
      _channel = WebSocketChannel.connect(uri);
      _isConnected = true;
      notifyListeners();

      _subscription = _channel!.stream.listen(
        (message) {
          try {
            final data = json.decode(message);
            _handleMessage(data);
          } catch (e) {
            debugPrint('Error parsing WebSocket message: $e');
          }
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
          _isConnected = false;
          notifyListeners();
        },
        onDone: () {
          debugPrint('WebSocket connection closed');
          _isConnected = false;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Error connecting WebSocket: $e');
      _isConnected = false;
      notifyListeners();
    }
  }

  void _handleMessage(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    
    switch (type) {
      case 'sensor_update':
        _latestSensorData = SensorData.fromJson(data['data'] as Map<String, dynamic>);
        notifyListeners();
        break;
      case 'alert':
        final alertJson = data['alert'] as Map<String, dynamic>;
        _latestAlert = Alert.fromJson(alertJson);
        notifyListeners();
        break;
      case 'config_update':
        // Config update will be handled by the service
        notifyListeners();
        break;
      case 'turn_event':
        // Turn event notification
        notifyListeners();
        break;
    }
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _subscription = null;
    _isConnected = false;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}

