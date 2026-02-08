#include "automation.h"

AutomationEngine::AutomationEngine(EnvironmentSensor& sensor, RelayController& relays, SettingsManager& settings, Scheduler& scheduler, NotificationManager& notifications)
    : _sensor(sensor), _relays(relays), _settings(settings), _scheduler(scheduler), _notifications(notifications), _currentMode(0) {}

void AutomationEngine::setMode(int mode) {
    _currentMode = mode;
}

void AutomationEngine::update() {
    // Check for alerts in ALL modes
    checkAlerts();

    if (_currentMode == 2) { // Schedule Mode
        _scheduler.update();
        return;
    }
    
    // Only run automation in AUTO mode (0)
    if (_currentMode != 0) return;

    checkTemperature();
    checkHumidity();
}

void AutomationEngine::checkAlerts() {
    float temp = _sensor.getTemperature();
    float humid = _sensor.getHumidity();
    SystemSettings s = _settings.getSettings();
    
    // Critical Thresholds (Hardcoded buffer for now, could be in settings)
    float alertTempHigh = s.tempMax + 2.0;
    float alertTempLow = s.tempMin - 2.0;
    
    // Temp High
    if (temp >= alertTempHigh && !_tempHighAlertSent) {
        _notifications.sendAlert("Temperature Critical High: " + String(temp, 1) + " C");
        _tempHighAlertSent = true;
    } else if (temp < (alertTempHigh - 1.0)) {
        _tempHighAlertSent = false;
    }
    
    // Temp Low
    if (temp <= alertTempLow && !_tempLowAlertSent) {
        _notifications.sendAlert("Temperature Critical Low: " + String(temp, 1) + " C");
        _tempLowAlertSent = true;
    } else if (temp > (alertTempLow + 1.0)) {
        _tempLowAlertSent = false;
    }
}

void AutomationEngine::checkTemperature() {
    float temp = _sensor.getTemperature();
    SystemSettings settings = _settings.getSettings();

    // Safety check for valid readings
    if (isnan(temp)) return;

    // Heater Logic (Low Temp)
    // Turn ON if below (min - hysteresis/2)
    // Turn OFF if above (min + hysteresis/2)
    if (temp < (settings.tempMin - settings.hysteresis)) {
        if (!_relays.getHeaterState()) {
            _relays.setHeater(true);
            Serial.println("Auto: Heater ON");
        }
    } else if (temp > (settings.tempMin + settings.hysteresis)) {
        if (_relays.getHeaterState()) {
            _relays.setHeater(false);
            Serial.println("Auto: Heater OFF");
        }
    }

    // Fan Logic (High Temp)
    // Turn ON if above (max + hysteresis)
    // Turn OFF if below (max - hysteresis)
    if (temp > (settings.tempMax + settings.hysteresis)) {
        if (!_relays.getFanState()) {
            _relays.setFan(true);
            Serial.println("Auto: Fan ON (Temp High)");
        }
    } else if (temp < (settings.tempMax - settings.hysteresis)) {
        // Fan OFF Logic
        // Fan should be OFF if:
        // 1. Temp is below max - hysteresis
        // 2. Humidity is below max - hysteresis (checked here to ensure we don't turn off if humidity needs it)
        
        bool humidityNeedsFan = false;
        if (!isnan(_sensor.getHumidity())) {
             if (_sensor.getHumidity() > (settings.humidMax + settings.hysteresis)) {
                 humidityNeedsFan = true;
             }
        }
        
        if (!humidityNeedsFan && _relays.getFanState()) {
            _relays.setFan(false);
            Serial.println("Auto: Fan OFF");
        }
    }
}

void AutomationEngine::checkHumidity() {
    float humid = _sensor.getHumidity();
    SystemSettings settings = _settings.getSettings();

    if (isnan(humid)) return;

    // Humidifier Logic (Low Humidity)
    if (humid < (settings.humidMin - settings.hysteresis)) {
        if (!_relays.getHumidifierState()) {
            _relays.setHumidifier(true);
            Serial.println("Auto: Humidifier ON");
        }
    } else if (humid > (settings.humidMin + settings.hysteresis)) {
        if (_relays.getHumidifierState()) {
            _relays.setHumidifier(false);
            Serial.println("Auto: Humidifier OFF");
        }
    }

    // Fan Logic (High Humidity) - coordinated with Temp control
    if (humid > (settings.humidMax + settings.hysteresis)) {
        if (!_relays.getFanState()) {
            _relays.setFan(true);
            Serial.println("Auto: Fan ON (Humidity High)");
        }
    } 
    // Turn OFF logic is handled in checkTemperature to avoid race conditions/fighting.
    // Basically, Fan OFF only if Temp < Max AND Humid < Max.
    // The checkTemperature function handles the "Turn OFF" case by checking humidity too.
}
