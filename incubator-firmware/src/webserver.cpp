#include "webserver.h"
#include <SPIFFS.h>

WebServerManager::WebServerManager(EnvironmentSensor& sensor, RelayController& relays, ServoController& servo, SettingsManager& settings, AutomationEngine& automation, Scheduler& scheduler, Logger& logger)
    : server(80), ws("/ws"), _sensor(sensor), _relays(relays), _servo(servo), _settings(settings), _automation(automation), _scheduler(scheduler), _logger(logger), lastWsPush(0) {}

void WebServerManager::begin() {
    if(!SPIFFS.begin(true)){
        Serial.println("An Error has occurred while mounting SPIFFS");
        return;
    }

    setupEndpoints();
    
    // Serve static files
    server.serveStatic("/", SPIFFS, "/").setDefaultFile("index.html");
    
    server.begin();
    Serial.println("Web Server started");
}

void WebServerManager::update() {
    ws.cleanupClients();

    // Push data to WebSocket clients every 2 seconds
    unsigned long currentMillis = millis();
    if (currentMillis - lastWsPush >= 2000) {
        lastWsPush = currentMillis;
        
        JsonDocument doc;
        doc["temp"] = _sensor.getTemperature();
        doc["humid"] = _sensor.getHumidity();
        doc["fan"] = _relays.getFanState();
        doc["heater"] = _relays.getHeaterState();
        doc["humidifier"] = _relays.getHumidifierState();
        
        String json;
        serializeJson(doc, json);
        ws.textAll(json);
    }
}

void WebServerManager::onEvent(AsyncWebSocket *server, AsyncWebSocketClient *client, AwsEventType type, void *arg, uint8_t *data, size_t len) {
    if (type == WS_EVT_CONNECT) {
        Serial.printf("WebSocket client #%u connected from %s\n", client->id(), client->remoteIP().toString().c_str());
    } else if (type == WS_EVT_DISCONNECT) {
        Serial.printf("WebSocket client #%u disconnected\n", client->id());
    } else if (type == WS_EVT_DATA) {
        handleWebSocketMessage(arg, data, len);
    }
}

void WebServerManager::handleWebSocketMessage(void *arg, uint8_t *data, size_t len) {
    AwsFrameInfo *info = (AwsFrameInfo*)arg;
    if (info->final && info->index == 0 && info->len == len && info->opcode == WS_TEXT) {
        // Handle incoming WebSocket messages if needed (e.g., control commands)
        // For now, we only push data
    }
}

void WebServerManager::setupEndpoints() {
    // WebSocket
    ws.onEvent(std::bind(&WebServerManager::onEvent, this, std::placeholders::_1, std::placeholders::_2, std::placeholders::_3, std::placeholders::_4, std::placeholders::_5, std::placeholders::_6));
    server.addHandler(&ws);

    // API: Status
    server.on("/api/status", HTTP_GET, [this](AsyncWebServerRequest *request) {
        JsonDocument doc;
        doc["temp"] = _sensor.getTemperature();
        doc["humid"] = _sensor.getHumidity();
        doc["fan"] = _relays.getFanState();
        doc["heater"] = _relays.getHeaterState();
        doc["humidifier"] = _relays.getHumidifierState();
        doc["servoAngle"] = _servo.getCurrentAngle();
        doc["time"] = _sensor.getDateTime();
        doc["mode"] = _automation.getMode(); // 0=Auto, 1=Manual, 2=Schedule
        
        String json;
        serializeJson(doc, json);
        request->send(200, "application/json", json);
    });

    // API: Config (Get)
    server.on("/api/config", HTTP_GET, [this](AsyncWebServerRequest *request) {
        SystemSettings s = _settings.getSettings();
        JsonDocument doc;
        doc["tempMin"] = s.tempMin;
        doc["tempMax"] = s.tempMax;
        doc["humidMin"] = s.humidMin;
        doc["humidMax"] = s.humidMax;
        doc["hysteresis"] = s.hysteresis;
        doc["useCelsius"] = s.useCelsius;
        doc["servoExtend"] = s.servoExtendAngle;
        doc["servoRetract"] = s.servoRetractAngle;
        doc["turnInterval"] = s.turnIntervalMinutes;
        
        // App Compatibility Fields
        doc["target_temp"] = (s.tempMin + s.tempMax) / 2.0; // Estimate target as midpoint
        doc["target_humidity"] = (s.humidMin + s.humidMax) / 2.0;
        doc["turn_interval_hours"] = s.turnIntervalMinutes / 60; // Convert mins to hours
        
        String json;
        serializeJson(doc, json);
        request->send(200, "application/json", json);
    });

    // API: Config (Post)
    AsyncCallbackJsonWebHandler *configHandler = new AsyncCallbackJsonWebHandler("/api/config", [this](AsyncWebServerRequest *request, JsonVariant &json) {
        JsonObject jsonObj = json.as<JsonObject>();
        
        if (jsonObj["tempMin"].is<float>()) _settings.setTempMin(jsonObj["tempMin"]);
        if (jsonObj["tempMax"].is<float>()) _settings.setTempMax(jsonObj["tempMax"]);
        if (jsonObj["humidMin"].is<float>()) _settings.setHumidMin(jsonObj["humidMin"]);
        if (jsonObj["humidMax"].is<float>()) _settings.setHumidMax(jsonObj["humidMax"]);
        if (jsonObj["hysteresis"].is<float>()) _settings.setHysteresis(jsonObj["hysteresis"]);
        
        // App Compatibility (target_temp -> Min/Max)
        if (jsonObj["target_temp"].is<float>()) {
             float target = jsonObj["target_temp"];
             // Default window +- 0.5 degrees
             _settings.setTempMin(target - 0.5);
             _settings.setTempMax(target + 0.5);
        }
        
        if (jsonObj["target_humidity"].is<float>()) {
             float target = jsonObj["target_humidity"];
             // Default window +- 5%
             _settings.setHumidMin(target - 5.0);
             _settings.setHumidMax(target + 5.0);
        }
        
        if (jsonObj["turn_interval_hours"].is<int>()) {
             int hours = jsonObj["turn_interval_hours"];
             SystemSettings s = _settings.getSettings();
             s.turnIntervalMinutes = hours * 60;
             _settings.saveSettings(s);
        }

        // New Settings
        if (jsonObj["servoExtend"].is<int>()) {
            SystemSettings s = _settings.getSettings();
            s.servoExtendAngle = jsonObj["servoExtend"];
            _settings.saveSettings(s);
        }
        if (jsonObj["servoRetract"].is<int>()) {
             SystemSettings s = _settings.getSettings();
             s.servoRetractAngle = jsonObj["servoRetract"];
             _settings.saveSettings(s);
        }
        if (jsonObj["turnInterval"].is<int>()) {
             SystemSettings s = _settings.getSettings();
             s.turnIntervalMinutes = jsonObj["turnInterval"];
             _settings.saveSettings(s);
        }
        
        
        Serial.println("API: Config updated.");
        request->send(200, "application/json", "{\"success\":true}");
    });
    server.addHandler(configHandler);

    // API: Control (Post)
    AsyncCallbackJsonWebHandler *controlHandler = new AsyncCallbackJsonWebHandler("/api/control", [this](AsyncWebServerRequest *request, JsonVariant &json) {
        JsonObject jsonObj = json.as<JsonObject>();
        
        // Mode Control
        if (jsonObj["mode"].is<int>()) {
             int newMode = jsonObj["mode"];
             _automation.setMode(newMode);
             // Also update global state if needed, but automation handles it
        }

        // Relay Control (Only works if Mode is Manual)
        // Ideally enforce mode check here, but AutomationEngine overwrites anyway if in Auto.
        if (jsonObj["fan"].is<bool>()) _relays.setFan(jsonObj["fan"]);
        if (jsonObj["heater"].is<bool>()) _relays.setHeater(jsonObj["heater"]);
        if (jsonObj["humidifier"].is<bool>()) _relays.setHumidifier(jsonObj["humidifier"]);
        
        // Servo Control
        if (jsonObj["servo"].is<int>()) _servo.moveToAngle(jsonObj["servo"]);
        if (jsonObj["turnEggs"].is<bool>() && jsonObj["turnEggs"].as<bool>()) {
             SystemSettings s = _settings.getSettings();
             // Turn Sequence (e.g. Extend then Retract?)
             // For now, toggle state based on current
             if (_servo.getCurrentAngle() < 45) {
                 _servo.turnEggs(true, s.servoExtendAngle, s.servoRetractAngle); // Extend
             } else {
                 _servo.turnEggs(false, s.servoExtendAngle, s.servoRetractAngle); // Retract
             }
        }
        
        request->send(200, "application/json", "{\"success\":true}");
    });
    server.addHandler(controlHandler);
    
    // API: Schedule (Get)
    server.on("/api/schedule", HTTP_GET, [this](AsyncWebServerRequest *request) {
        std::vector<Schedule> schedules = _scheduler.getSchedules();
        JsonDocument doc;
        JsonArray arr = doc.to<JsonArray>();
        
        for (const auto& s : schedules) {
            JsonObject obj = arr.add<JsonObject>();
            obj["id"] = s.id;
            obj["startHour"] = s.startHour;
            obj["startMinute"] = s.startMinute;
            obj["endHour"] = s.endHour;
            obj["endMinute"] = s.endMinute;
            obj["deviceType"] = s.deviceType;
            obj["activeState"] = s.activeState;
            obj["daysMask"] = s.daysMask;
            obj["enabled"] = s.enabled;
        }
        
        String json;
        serializeJson(doc, json);
        request->send(200, "application/json", json);
    });
    
    // API: Schedule (Post - Add/Edit)
    AsyncCallbackJsonWebHandler *scheduleHandler = new AsyncCallbackJsonWebHandler("/api/schedule", [this](AsyncWebServerRequest *request, JsonVariant &json) {
        JsonObject jsonObj = json.as<JsonObject>();
        
        Schedule s;
        s.id = jsonObj["id"] | 0; // 0 means new
        s.startHour = jsonObj["startHour"];
        s.startMinute = jsonObj["startMinute"];
        s.endHour = jsonObj["endHour"];
        s.endMinute = jsonObj["endMinute"];
        s.deviceType = jsonObj["deviceType"];
        s.activeState = jsonObj["activeState"] | true;
        s.daysMask = jsonObj["daysMask"] | 127; // Default all days
        s.enabled = jsonObj["enabled"] | true;
        
        if (s.id > 0) {
            _scheduler.removeSchedule(s.id); // Remove existing to replace
        }
        _scheduler.addSchedule(s);
        
        request->send(200, "application/json", "{\"success\":true}");
    });
    server.addHandler(scheduleHandler);
    
    // API: Schedule (Delete)
    // Using POST for delete simplify, or DELETE method. Let's use DELETE with query param id
    server.on("/api/schedule", HTTP_DELETE, [this](AsyncWebServerRequest *request) {
        if (request->hasParam("id")) {
            uint8_t id = request->getParam("id")->value().toInt();
            _scheduler.removeSchedule(id);
            request->send(200, "application/json", "{\"success\":true}");
        } else {
            request->send(400, "application/json", "{\"error\":\"Missing id\"}");
        }
    });
    
    // API: History (Get)
    server.on("/api/history", HTTP_GET, [this](AsyncWebServerRequest *request) {
        String json = _logger.getHistoryJson();
        request->send(200, "application/json", json); // Directly send array
    });
    
    // API: Analytics (Get)
    server.on("/api/analytics", HTTP_GET, [this](AsyncWebServerRequest *request) {
        SystemSettings s = _settings.getSettings();
        JsonDocument doc;
        
        // Mock calculations based on current state
        // In a real system, we'd analyze history.
        
        // Days Remaining
        int daysRemaining = 21; // Default for chicken
        if (s.incubationStartDate > 0) {
             unsigned long now = _sensor.now().unixtime(); // Assuming RTC works
             long elapsedSeconds = now - s.incubationStartDate;
             int elapsedDays = elapsedSeconds / 86400;
             daysRemaining = 21 - elapsedDays;
             if (daysRemaining < 0) daysRemaining = 0;
        }
        
        doc["predicted_success_rate"] = 0.85; // Mock
        doc["days_remaining"] = daysRemaining;
        
        // Scores (Mock based on current deviation)
        float currentTemp = _sensor.getTemperature();
        float tempDiff = abs(currentTemp - s.tempMin);
        int tempScore = 100 - (tempDiff * 10);
        if (tempScore < 0) tempScore = 0;
        
        float currentHumid = _sensor.getHumidity();
        float humidDiff = abs(currentHumid - s.humidMin);
        int humidScore = 100 - (humidDiff * 2);
        if (humidScore < 0) humidScore = 0;

        doc["temp_stability_score"] = tempScore;
        doc["humidity_score"] = humidScore;
        doc["turn_compliance"] = 100; // Mock
        
        JsonArray recs = doc.createNestedArray("recommendations");
        if (tempScore < 80) recs.add("Check Heater/Fan");
        if (humidScore < 80) recs.add("Check Water Level");
        if (recs.size() == 0) recs.add("System Optimal");
        
        String json;
        serializeJson(doc, json);
        request->send(200, "application/json", json);
    });

    // API: Time Sync (Post)
    AsyncCallbackJsonWebHandler *timeHandler = new AsyncCallbackJsonWebHandler("/api/time", [this](AsyncWebServerRequest *request, JsonVariant &json) {
        JsonObject jsonObj = json.as<JsonObject>();
        if (jsonObj["epoch"].is<unsigned long>()) {
            unsigned long epoch = jsonObj["epoch"];
            _sensor.setTime(epoch);
            request->send(200, "application/json", "{\"success\":true}");
        } else {
            request->send(400, "application/json", "{\"error\":\"Missing epoch\"}");
        }
    });
    server.addHandler(timeHandler);
}
