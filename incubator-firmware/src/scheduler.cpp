#include "scheduler.h"

Scheduler::Scheduler(EnvironmentSensor& sensor, RelayController& relays, SettingsManager& settings)
    : _sensor(sensor), _relays(relays), _settings(settings) {}

void Scheduler::begin() {
    loadSchedules();
}

void Scheduler::update() {
    // This function is called when System Mode is SCHEDULE.
    // Logic: Look for any active schedule for each device.
    // If multiple schedules for same device overlap, last one wins? Or OR logic?
    // Let's assume logical OR for "ON" state. If ANY schedule says ON, it's ON.
    // If NO schedule says ON, it's OFF (default).
    
    // Get current time
    DateTime now = _sensor.now();
    uint8_t currentHour = now.hour();
    uint8_t currentMinute = now.minute();
    uint8_t currentDay = now.dayOfTheWeek(); // 0=Sun, 6=Sat

    bool fanState = false;
    bool heaterState = false;
    bool humidState = false;

    for (const auto& s : schedules) {
        if (!s.enabled) continue;
        
        // Check Day
        if (!((s.daysMask >> currentDay) & 1)) continue;

        // Check Time
        if (isTimeInRange(currentHour, currentMinute, s.startHour, s.startMinute, s.endHour, s.endMinute)) {
            // Schedule is active
            if (s.deviceType == 0) { // Fan
                if (s.activeState) fanState = true; 
            } else if (s.deviceType == 1) { // Heater
                if (s.activeState) heaterState = true;
            } else if (s.deviceType == 2) { // Humidifier
                if (s.activeState) humidState = true;
            }
        }
    }

    // Apply states
    if (_relays.getFanState() != fanState) {
        _relays.setFan(fanState); // Only update if changed to avoid spamming logs/relays
         Serial.printf("Schedule: Fan set to %s\n", fanState ? "ON" : "OFF");
    }
    if (_relays.getHeaterState() != heaterState) {
        _relays.setHeater(heaterState);
        Serial.printf("Schedule: Heater set to %s\n", heaterState ? "ON" : "OFF");
    }
    if (_relays.getHumidifierState() != humidState) {
        _relays.setHumidifier(humidState);
        Serial.printf("Schedule: Humidifier set to %s\n", humidState ? "ON" : "OFF");
    }
}

bool Scheduler::isTimeInRange(uint8_t currentHour, uint8_t currentMinute, uint8_t startH, uint8_t startM, uint8_t endH, uint8_t endM) {
    int current = currentHour * 60 + currentMinute;
    int start = startH * 60 + startM;
    int end = endH * 60 + endM;

    if (start < end) {
        return (current >= start && current < end);
    } else {
        // Crossover midnight (e.g. 22:00 to 06:00)
        return (current >= start || current < end);
    }
}

bool Scheduler::addSchedule(Schedule s) {
    if (schedules.size() >= MAX_SCHEDULES) return false;
    // Assign ID if 0
    if (s.id == 0) {
        // Find max ID
        int maxId = 0;
        for (const auto& sch : schedules) {
            if (sch.id > maxId) maxId = sch.id;
        }
        s.id = maxId + 1;
    }
    schedules.push_back(s);
    saveSchedules();
    return true;
}

bool Scheduler::removeSchedule(uint8_t id) {
    for (auto it = schedules.begin(); it != schedules.end(); ++it) {
        if (it->id == id) {
            schedules.erase(it);
            saveSchedules();
            return true;
        }
    }
    return false;
}

void Scheduler::clearSchedules() {
    schedules.clear();
    saveSchedules();
}

std::vector<Schedule> Scheduler::getSchedules() {
    return schedules;
}

void Scheduler::saveSchedules() {
    Preferences prefs;
    prefs.begin("schedules", false);
    
    // Simple serialization: Count + Array
    prefs.putUChar("count", schedules.size());
    
    for (size_t i = 0; i < schedules.size(); i++) {
        String key = "s" + String(i);
        // We need to store a struct. Preferences.putBytes is good.
        // But putBytes limit?
        // Let's assume putBytes works for small struct (8 bytes).
        prefs.putBytes(key.c_str(), &schedules[i], sizeof(Schedule));
    }
    prefs.end();
    Serial.println("Schedules saved.");
}

void Scheduler::loadSchedules() {
    Preferences prefs;
    prefs.begin("schedules", true);
    
    uint8_t count = prefs.getUChar("count", 0);
    schedules.clear();
    
    for (size_t i = 0; i < count; i++) {
        String key = "s" + String(i);
        Schedule s;
        if (prefs.getBytes(key.c_str(), &s, sizeof(Schedule)) == sizeof(Schedule)) {
            schedules.push_back(s);
        }
    }
    prefs.end();
    Serial.printf("Loaded %d schedules.\n", schedules.size());
}
