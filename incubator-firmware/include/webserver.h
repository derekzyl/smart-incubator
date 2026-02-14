#ifndef INCUBATOR_WEBSERVER_H
#define INCUBATOR_WEBSERVER_H

#include <Arduino.h>
#include <ESPAsyncWebServer.h>
#include <AsyncJson.h>
#include <ArduinoJson.h>
#include "config.h"
#include "sensors.h"
#include "relays.h"
#include "servo_control.h"
#include "storage.h"
#include "automation.h"
#include "scheduler.h"

class WebServerManager {
public:
    WebServerManager(EnvironmentSensor& sensor, RelayController& relays, ServoController& servo, SettingsManager& settings, AutomationEngine& automation, Scheduler& scheduler);
    void begin();
    void update(); // Handle WebSocket cleanup if needed

private:
    AsyncWebServer server;
    AsyncWebSocket ws;
    EnvironmentSensor& _sensor;
    RelayController& _relays;
    ServoController& _servo;
    SettingsManager& _settings;
    AutomationEngine& _automation;
    Scheduler& _scheduler;

    void setupEndpoints();
    void handleWebSocketMessage(void *arg, uint8_t *data, size_t len);
    void onEvent(AsyncWebSocket *server, AsyncWebSocketClient *client, AwsEventType type, void *arg, uint8_t *data, size_t len);
    unsigned long lastWsPush;
};

#endif // INCUBATOR_WEBSERVER_H
