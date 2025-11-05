# Smart Incubator Firmware

ESP32 firmware for the Smart Incubator system.

## Configuration

Before uploading, update these values in `src/main.cpp`:

1. **WiFi credentials:**
   ```cpp
   const char* ssid = "YOUR_WIFI_SSID";
   const char* password = "YOUR_WIFI_PASSWORD";
   ```

2. **API endpoint:**
   ```cpp
   const char* apiUrl = "http://YOUR_SERVER_IP:8000/api/v1/sensors/upload";
   const char* incubatorId = "your-incubator-id";
   ```

3. **Control parameters:**
   ```cpp
   double targetTemp = 37.5;        // Target temperature (°C)
   double targetHumidity = 55.0;     // Target humidity (%)
   int turnIntervalHours = 4;        // Hours between turns
   int turnAngle = 45;               // Degrees to turn eggs
   ```

4. **Stepper motor steps:**
   Adjust `stepsPerTurn` based on your motor and gearing:
   ```cpp
   const int stepsPerTurn = 200;  // Adjust for your setup
   ```

## PID Tuning

The PID controller uses these default values:
- Kp = 2.0
- Ki = 5.0
- Kd = 1.0

Tune these values based on your heater response time and incubator thermal mass.

## Building and Uploading

1. Install PlatformIO
2. Open this project in PlatformIO
3. Update configuration in `src/main.cpp`
4. Build and upload:
   ```bash
   pio run -t upload
   ```

## Pin Connections

- **DS18B20 sensors:** GPIO4 (1-wire bus)
- **SHT31:** GPIO21 (SDA), GPIO22 (SCL)
- **RTC DS3231:** GPIO21 (SDA), GPIO22 (SCL) - shared I2C bus
- **Heater SSR:** GPIO25
- **Fan PWM:** GPIO26
- **Humidifier Relay:** GPIO27
- **Buzzer:** GPIO14
- **Stepper:** GPIO32 (STEP), GPIO33 (DIR), GPIO13 (ENABLE)
- **LEDs:** GPIO2 (heater), GPIO12 (humidifier), GPIO15 (status)

## Testing

1. Monitor serial output at 115200 baud
2. Check sensor readings appear every 5 seconds
3. Verify data uploads to API every 30 seconds
4. Test egg turning by adjusting `turnIntervalHours` to 1 minute for testing

