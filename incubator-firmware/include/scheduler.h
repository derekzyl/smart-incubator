#ifndef SCHEDULER_H
#define SCHEDULER_H

#include <Arduino.h>
#include <vector>
#include <ArduinoJson.h>
#include "sensors.h"
#include "relays.h"
#include "storage.h"

// Max schedules
#define MAX_SCHEDULES 20

struct Schedule {
    uint8_t id;
    uint8_t startHour;
    uint8_t startMinute;
    uint8_t endHour;
    uint8_t endMinute;
    uint8_t deviceType; // 0=Fan, 1=Heater, 2=Humidifier
    bool activeState;   // true=ON, false=OFF
    uint8_t daysMask;   // Bit 0=Sun, 1=Mon, ..., 6=Sat
    bool enabled;
};

class Scheduler {
public:
    Scheduler(EnvironmentSensor& sensor, RelayController& relays, SettingsManager& settings);
    void begin();
    void update(); // Checks time and applies schedules if in Schedule Mode

    // CRUD
    bool addSchedule(Schedule s);
    bool removeSchedule(uint8_t id);
    void clearSchedules();
    std::vector<Schedule> getSchedules();
    
    // Persistence
    void saveSchedules();
    void loadSchedules();

private:
    EnvironmentSensor& _sensor;
    RelayController& _relays;
    SettingsManager& _settings;
    std::vector<Schedule> schedules;
    
    bool isTimeInRange(uint8_t currentHour, uint8_t currentMinute, uint8_t startH, uint8_t startM, uint8_t endH, uint8_t endM);
    uint8_t getDayOfWeek(); // 0=Sun...6=Sat
};

#endif // SCHEDULER_H
