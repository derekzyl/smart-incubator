#ifndef CONFIG_H
#define CONFIG_H

#include <Arduino.h>

// --- Pin Definitions ---

// Relays
#define PIN_RELAY_FAN       13
#define PIN_RELAY_HEATER    33
#define PIN_RELAY_HUMID     23

// Relay Logic (BC547 NPN Switch - Active HIGH)
#define RELAY_ACTIVE_LOW    false 
#define RELAY_ON            (RELAY_ACTIVE_LOW ? LOW : HIGH)
#define RELAY_OFF           (RELAY_ACTIVE_LOW ? HIGH : LOW)

// Stepper Motor (ULN2003 / 28BYJ-48)
#define PIN_STEPPER_IN1     16 // RX2
#define PIN_STEPPER_IN2     17 // TX2
#define PIN_STEPPER_IN3     18
#define PIN_STEPPER_IN4     19

// Buttons
#define PIN_BUTTON_MODE     4
#define PIN_BUTTON_SET      35 // Note: GPIO 35 is Input Only, needs EXTERNAL 10k PULL-UP resistor

// Sensors
#define PIN_DHT             32

// I2C (LCD + RTC)
#define PIN_I2C_SDA         21
#define PIN_I2C_SCL         22

// --- WiFi Configuration ---
#define WIFI_SSID           "cybergenii"
#define WIFI_PASS           "12341234"
#define AP_SSID             "SmartIncubator_AP"
#define AP_PASS             "incubator123"

// --- System Configuration ---

// Telegram Configuration
#define TELEGRAM_BOT_TOKEN  "8579627355:AAGkoki40J8X4P8jL6oAwselL_SKbRfMh8A" // Get from @BotFather
#define TELEGRAM_CHAT_ID    "2135710999"   // Get from @IDBot

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
