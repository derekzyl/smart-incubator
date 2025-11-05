# Smart Incubator Mobile App

Flutter mobile application for monitoring and controlling the Smart Incubator system.

## Features

- **Live Dashboard**: Real-time temperature and humidity gauges
- **Historical Charts**: 7-day temperature and humidity graphs
- **Analytics**: Hatch success prediction and performance metrics
- **Settings**: Configure target temperature, humidity, and turn intervals
- **WebSocket Updates**: Real-time sensor data without polling
- **Alerts**: Visual notifications for critical conditions

## Setup

1. Install Flutter SDK (3.9.2 or later)

2. Install dependencies:
```bash
flutter pub get
```

3. Update API endpoint in `lib/services/incubator_service.dart`:
```dart
static const String baseUrl = 'http://YOUR_SERVER_IP:8000/api/v1';
```

4. Update WebSocket URL in `lib/services/websocket_service.dart`:
```dart
static const String wsBaseUrl = 'ws://YOUR_SERVER_IP:8000/ws/live';
```

5. Run the app:
```bash
flutter run
```

## Building

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## Project Structure

```
lib/
├── main.dart              # App entry point
├── models/               # Data models
│   ├── sensor_data.dart
│   ├── incubator_config.dart
│   └── alert.dart
├── services/            # API and WebSocket services
│   ├── incubator_service.dart
│   └── websocket_service.dart
├── screens/             # App screens
│   ├── dashboard_screen.dart
│   ├── history_screen.dart
│   ├── analytics_screen.dart
│   └── settings_screen.dart
└── widgets/             # Reusable widgets
    ├── temp_gauge.dart
    └── humidity_gauge.dart
```

## Configuration

The app uses a default incubator ID for demo purposes. In production, implement user authentication and incubator selection.
