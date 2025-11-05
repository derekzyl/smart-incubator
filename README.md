# Smart Incubator with Automatic Egg Turning

A precision-controlled egg incubator system with real-time monitoring, automatic egg turning, and cloud-connected analytics.

## System Overview

This project consists of three main components:

1. **ESP32 Firmware** (`incubator-firmware/`) - Embedded controller with sensor reading, PID temperature control, and egg turning
2. **FastAPI Backend** (`backend/`) - REST API and WebSocket server for data logging and analytics
3. **Flutter Mobile App** (`incubator_app/`) - Cross-platform mobile app for monitoring and control

## Features

- **Dual-Sensor Temperature Monitoring**: DS18B20 and SHT31 sensors for redundancy
- **PID Temperature Control**: Precise temperature regulation with automatic heater control
- **Automated Humidity Control**: Ultrasonic humidifier with automatic on/off
- **Automatic Egg Turning**: Stepper motor-based turning every 2-4 hours
- **Real-Time Monitoring**: WebSocket-based live updates to mobile app
- **Historical Analytics**: 7-day charts and hatch success prediction
- **Alert System**: Critical temperature/humidity alerts with notifications
- **RTC-Based Scheduling**: Turning schedule survives power outages

## Hardware Requirements

See the detailed component list in the project specification. Key components:

- ESP32-WROOM-32D microcontroller
- DS18B20 temperature sensors (×2)
- SHT31 temperature/humidity sensor
- DS3231 RTC module
- NEMA 17 stepper motor with DRV8825 driver
- SSR-25DA solid state relay for heater control
- 12V DC fans and ultrasonic mist maker
- Ceramic PTC heater (12V 100W)

## Quick Start

### 1. Backend Setup

```bash
cd backend
pip install -r requirements.txt
cp .env.example .env
# Edit .env with your configuration
python main.py
```

Backend will run on `http://localhost:8000`

### 2. Flutter App Setup

```bash
cd incubator_app
flutter pub get
# Update API endpoints in services
flutter run
```

### 3. ESP32 Firmware Setup

```bash
cd incubator-firmware
# Install PlatformIO
# Open project in PlatformIO
# Update WiFi and API settings in src/main.cpp
pio run -t upload
```

## Project Structure

```
incubator/
├── backend/                 # FastAPI backend
│   ├── main.py             # Main application
│   ├── requirements.txt    # Python dependencies
│   └── README.md
├── incubator_app/          # Flutter mobile app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/
│   │   ├── services/
│   │   ├── screens/
│   │   └── widgets/
│   ├── pubspec.yaml
│   └── README.md
├── incubator-firmware/     # ESP32 firmware
│   ├── src/
│   │   └── main.cpp       # Main firmware code
│   ├── platformio.ini     # PlatformIO configuration
│   └── README.md
└── README.md              # This file
```

## Configuration

### Backend
- Update `DATABASE_URL` in `.env` for database connection
- Configure `REDIS_URL` for WebSocket support (optional)
- Set `TWILIO_*` credentials for SMS alerts (optional)

### Flutter App
- Update `baseUrl` in `lib/services/incubator_service.dart`
- Update `wsBaseUrl` in `lib/services/websocket_service.dart`
- Configure incubator ID (currently uses demo ID)

### ESP32 Firmware
- Set WiFi SSID and password
- Configure API endpoint URL
- Set target temperature and humidity
- Adjust PID parameters for your heater setup
- Configure stepper motor steps based on your gearing

## API Documentation

Once the backend is running, visit:
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

## Safety Features

- Thermal fuse (77°C) for overheat protection
- Dual temperature sensors for redundancy
- Sensor disagreement detection (>2°C difference triggers alert)
- Critical temperature alarms (<35°C or >40°C)
- Emergency stop capability via mobile app

## Development

### Testing Backend
```bash
cd backend
pytest  # If tests are added
```

### Testing Flutter App
```bash
cd incubator_app
flutter test
```

### Monitoring ESP32
Connect via serial monitor at 115200 baud to view sensor readings and system status.

## License

This project is provided as-is for educational and personal use.

## Support

For issues or questions, please refer to the individual component README files or create an issue in the repository.
