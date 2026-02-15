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

// Servo Motor (Egg Turner)
#define PIN_SERVO           18
#define DEFAULT_SERVO_RETRACT 0
#define DEFAULT_SERVO_EXTEND  170 // Increased from 90 per user request
#define DEFAULT_TURN_INTERVAL 240 // Minutes (4 hours for chicken eggs)


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



// Default Thresholds for egg hatching (chicken eggs - can be overridden by app/NVS)
#define DEFAULT_TEMP_MIN    37.0
#define DEFAULT_TEMP_MAX    38.0
#define DEFAULT_HUMID_MIN   50.0
#define DEFAULT_HUMID_MAX   65.0
#define DEFAULT_HYSTERESIS  0.5

#endif // CONFIG_H
