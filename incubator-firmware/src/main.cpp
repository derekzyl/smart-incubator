#include <Arduino.h>
#include "config.h"
#include "sensors.h"
#include "relays.h"
#include "servo_control.h"
#include "display.h"
#include "buttons.h"
#include "storage.h"
#include "automation.h"
#include "wifi_manager.h"
#include "webserver.h"
#include "scheduler.h"
#include "notifications.h"
#include "logger.h"

// --- Global Objects ---
EnvironmentSensor envSensor;
RelayController relays;
ServoController servo;
DisplayController display;

ButtonHandler buttons;
SettingsManager settingsManager;
Scheduler scheduler(envSensor, relays, settingsManager);
NotificationManager notifications;
Logger logger;
AutomationEngine automation(envSensor, relays, servo, settingsManager, scheduler, notifications);
WifiManager wifiManager;
WebServerManager webServer(envSensor, relays, servo, settingsManager, automation, scheduler, logger);


// System Mode managed by AutomationEngine

void setup() {
    Serial.begin(SERIAL_BAUD_RATE);
    Serial.println("Starting ESP32 Environmental Control System...");

    // Initialize Modules
    settingsManager.begin();
    envSensor.begin();
    scheduler.begin(); // Load schedules
    notifications.begin();
    logger.begin();
    relays.begin();
    servo.begin();
    display.begin();
    buttons.begin();
    
    // Connect to WiFi
    wifiManager.begin();
    
    // Start Web Server
    webServer.begin();

    Serial.println("Initialization Complete.");
}

void loop() {
    // 0. Update WiFi & WebServer
    wifiManager.update();
    webServer.update();

    // 1. Update Sensors
    envSensor.update();

    // Notify IP on Connection
    static bool ipSent = false;
    if (wifiManager.isConnected()) {
        if (!ipSent) {
            String ip = wifiManager.getIP();
            float temp = envSensor.getTemperature();
            String msg = "✅ *Incubator Online*\n\n";
            msg += "IP Address: `" + ip + "`\n";
            msg += "Temp: " + String(temp, 1) + "°C";
            notifications.sendMessage(msg);
            ipSent = true;
        }
    } else {
        ipSent = false;
    }

    // 2. Handle Buttons
    int currentMode = automation.getMode();
    if (buttons.isModeButtonPressed()) {
        if (currentMode == 0) currentMode = 1; // Auto -> Manual
        else if (currentMode == 1) currentMode = 2; // Manual -> Schedule
        else currentMode = 0; // Schedule -> Auto
        
        automation.setMode(currentMode); 
        
        Serial.print("Mode changed to: ");
        Serial.println(currentMode);
    }
    
    // (Button 2 logic: Toggle Fan manually if in Manual Mode)
    if (buttons.isSetButtonPressed()) {
        Serial.println("Set button pressed");
        Serial.printf("Current mode: %d\n", automation.getMode());
        if (automation.getMode() == 1) { // Manual
            bool state = relays.getFanState();
            relays.setFan(!state);
            Serial.printf("Manual: Fan toggled to %s\n", !state ? "ON" : "OFF");
        } else {
            Serial.println("Not in manual mode - fan toggle ignored");
        }
    }

    // 3. Update Stepper (Not needed for Servo)
    // servo.update(); 


    // 4. Update Display (Rate Limited to 500ms)
    static unsigned long lastDisplayUpdate = 0;
    if (millis() - lastDisplayUpdate > 500) {
        lastDisplayUpdate = millis();
        
        String modeStr;
        int m = automation.getMode();
        if (m == 0) modeStr = "AUTO";
        else if (m == 1) modeStr = "MAN "; 
        else modeStr = "SCHD";

        display.update(
            envSensor.getTemperature(),
            envSensor.getHumidity(),
            envSensor.getDateTime(),
            relays.getFanState(),
            relays.getHeaterState(),
            relays.getHumidifierState(),
            modeStr,
            wifiManager.getIP()
        );
    }

    // 5. Automation Logic
    automation.update();

    // 6. Data Logging (Every 5 minutes)
    static unsigned long lastLogTime = 0;
    if (millis() - lastLogTime > 300000) { // 300000 ms = 5 mins
        lastLogTime = millis();
        // Only log if time is valid (year > 2000)
        String dt = envSensor.getDateTime();
        if (dt.indexOf("2000") == -1) { // Simple check, better would be year check
             logger.logData(envSensor.getTemperature(), envSensor.getHumidity(), dt);
             Serial.println("Data logged.");
        } else {
             // Fallback: Log anyway for debugging/demo purposes even if time is wrong
             logger.logData(envSensor.getTemperature(), envSensor.getHumidity(), dt);
             Serial.println("Data logged (Time not synced).");
        }
    }
    
    // Heartbeat (Every 1s)
    static unsigned long lastHeartbeat = 0;
    if (millis() - lastHeartbeat > 1000) {
        lastHeartbeat = millis();
        Serial.println("Loop running...");
    }

    // Comprehensive Debug Status (Every 5s)
    static unsigned long lastDebug = 0;
    if (millis() - lastDebug > 5000) {
        lastDebug = millis();
        Serial.println("=== SYSTEM STATUS ===");
        float t = envSensor.getTemperature();
        float h = envSensor.getHumidity();
        Serial.printf("Mode: %d | Temp: %.1f | Humid: %.1f\n", automation.getMode(), t, h);
        if (isnan(t) || isnan(h)) Serial.println("WARNING: Sensor reading is NAN");
        
        Serial.println("====================");
        Serial.printf("Heater: %s | Fan: %s | Humidifier: %s\n",
            relays.getHeaterState() ? "ON" : "OFF",
            relays.getFanState() ? "ON" : "OFF",
            relays.getHumidifierState() ? "ON" : "OFF");
        Serial.println("====================");
    }
}
