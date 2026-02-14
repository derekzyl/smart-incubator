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

// --- Global Objects ---
EnvironmentSensor envSensor;
RelayController relays;
ServoController servo;
DisplayController display;

ButtonHandler buttons;
SettingsManager settingsManager;
Scheduler scheduler(envSensor, relays, settingsManager);
NotificationManager notifications;
AutomationEngine automation(envSensor, relays, settingsManager, scheduler, notifications);
WifiManager wifiManager;
WebServerManager webServer(envSensor, relays, servo, settingsManager, automation, scheduler);


// System Mode
enum SystemMode { MODE_AUTO, MODE_MANUAL, MODE_SCHEDULE };
SystemMode currentMode = MODE_AUTO;

void setup() {
    Serial.begin(SERIAL_BAUD_RATE);
    Serial.println("Starting ESP32 Environmental Control System...");

    // Initialize Modules
    settingsManager.begin();
    envSensor.begin();
    scheduler.begin(); // Load schedules
    notifications.begin();
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
    if (buttons.isModeButtonPressed()) {
        if (currentMode == MODE_AUTO) currentMode = MODE_MANUAL;
        else if (currentMode == MODE_MANUAL) currentMode = MODE_SCHEDULE;
        else currentMode = MODE_AUTO;
        
        automation.setMode((int)currentMode); 
        
        Serial.print("Mode changed to: ");
        Serial.println(currentMode);
    }
    
    // (Button 2 logic: Toggle Fan manually if in Manual Mode)
    if (buttons.isSetButtonPressed()) {
         Serial.println("Set button pressed");
         if (currentMode == MODE_MANUAL) {
             bool state = relays.getFanState();
             relays.setFan(!state);
             Serial.printf("Manual: Fan toggled to %s\n", !state ? "ON" : "OFF");
         }
    }

    // 3. Update Stepper (Not needed for Servo)
    // servo.update(); 


    // 4. Update Display
    String modeStr;
    if (currentMode == MODE_AUTO) modeStr = "AUTO";
    else if (currentMode == MODE_MANUAL) modeStr = "MAN "; 
    else modeStr = "SCHD";

    display.update(
        envSensor.getTemperature(),
        envSensor.getHumidity(),
        envSensor.getDateTime(),
        relays.getFanState(),
        relays.getHeaterState(),
        relays.getHumidifierState(),
        modeStr
    );

    // 5. Automation Logic
    automation.update();
}
