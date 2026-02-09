#ifndef INCUBATOR_AUTOMATION_H
#define INCUBATOR_AUTOMATION_H

#include <Arduino.h>
#include "sensors.h"
#include "relays.h"
#include "storage.h"
#include "scheduler.h"
#include "notifications.h"

class AutomationEngine {
public:
    AutomationEngine(EnvironmentSensor& sensor, RelayController& relays, SettingsManager& settings, Scheduler& scheduler, NotificationManager& notifications);
    void update();
    void setMode(int mode); // 0=Auto, 1=Manual, 2=Schedule
    int getMode() const { return _currentMode; }

private:
    EnvironmentSensor& _sensor;
    RelayController& _relays;
    SettingsManager& _settings;
    Scheduler& _scheduler;
    NotificationManager& _notifications;
    int _currentMode;
    
    // Alert State
    bool _tempHighAlertSent = false;
    bool _tempLowAlertSent = false;
    bool _humidHighAlertSent = false;
    bool _humidLowAlertSent = false;
    unsigned long _lastAlertTime = 0;

    void checkAlerts();
    void checkTemperature();
    void checkHumidity();
};

#endif // INCUBATOR_AUTOMATION_H
