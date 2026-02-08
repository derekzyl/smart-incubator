#ifndef CONFIG_H
#define CONFIG_H

#include <Arduino.h>

// --- Pin Definitions ---

// Relays
#define PIN_RELAY_FAN       32
#define PIN_RELAY_HEATER    33
#define PIN_RELAY_HUMID     23

// Stepper Motor
#define PIN_STEPPER_STEP    19
#define PIN_STEPPER_DIR     18
#define PIN_STEPPER_ENABLE  17
#define PIN_STEPPER_MS      16

// Buttons
#define PIN_BUTTON_MODE     4
#define PIN_BUTTON_SET      35

// Sensors
#define PIN_DHT             13

// I2C (LCD + RTC)
#define PIN_I2C_SDA         21
#define PIN_I2C_SCL         22

// --- WiFi Configuration ---
#define WIFI_SSID           "YOUR_SSID"
#define WIFI_PASS           "YOUR_PASSWORD"

// --- System Configuration ---

// Serial Communication
#define SERIAL_BAUD_RATE    115200

// Sensor Settings
#define DHT_TYPE            DHT22

// Stepper Settings
#define STEPPER_MAX_SPEED   1000
#define STEPPER_ACCEL       500

// Default Thresholds (can be overridden by NVS)
#define DEFAULT_TEMP_MIN    20.0
#define DEFAULT_TEMP_MAX    25.0
#define DEFAULT_HUMID_MIN   40.0
#define DEFAULT_HUMID_MAX   60.0
#define DEFAULT_HYSTERESIS  1.0

#endif // CONFIG_H
