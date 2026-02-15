#include "automation.h"

AutomationEngine::AutomationEngine(EnvironmentSensor& sensor, RelayController& relays, ServoController& servo, SettingsManager& settings, Scheduler& scheduler, NotificationManager& notifications)
    : _sensor(sensor), _relays(relays), _servo(servo), _settings(settings), _scheduler(scheduler), _notifications(notifications), _currentMode(0), _lastTurnTime(0), _isServoExtended(false) {}

void AutomationEngine::setMode(int mode) {
    if (_currentMode != mode) {
        _currentMode = mode;
        if (_currentMode == 0) { // Switching TO Auto Mode
            // Reset all relays to OFF to ensure clean state and override Manual settings
            _relays.setFan(false);
            _relays.setHeater(false);
            _relays.setHumidifier(false);
            Serial.println("Switched to Auto Mode: Resetting all relays.");
        }
    }
}

void AutomationEngine::update() {
    // Check for alerts in ALL modes
    checkAlerts();

    if (_currentMode == 2) { // Schedule Mode
        _scheduler.update();
        return;
    }
    
    // Only run automation in AUTO mode (0)
    if (_currentMode != 0) {
        static unsigned long lastModeDebug = 0;
        if (millis() - lastModeDebug > 5000) {
            lastModeDebug = millis();
            Serial.printf("[Auto] Skipped: System is in %s Mode (Not Auto)\n", 
                _currentMode == 1 ? "MANUAL" : "SCHEDULE");
        }
        return;
    }

    checkTemperature();
    checkHumidity();
    checkEggTurning();
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
    if (isnan(temp)) {
        Serial.println("Auto: Temp is NAN!");
        return;
    }

    // Debugging (Every 3 seconds)
    static unsigned long lastTempDebug = 0;
    if (millis() - lastTempDebug > 3000) {
        lastTempDebug = millis();
        // Show Min/Max so user knows the active range
        Serial.printf("[Auto] Temp: %.1f C | Range: %.1f - %.1f C | Heater: %s | Fan: %s\n", 
            temp, settings.tempMin, settings.tempMax, 
            _relays.getHeaterState() ? "ON" : "OFF",
            _relays.getFanState() ? "ON" : "OFF");
            
        if (temp < settings.tempMin) Serial.println("-> Logic: Too Cold (Heater ON)");
        else if (temp > settings.tempMax) Serial.println("-> Logic: Too Hot (Fan ON)");
        else Serial.println("-> Logic: Safe Zone (Idle)");
    }

    // Heater Logic
    // Turn ON if below (min)
    // Turn OFF if above (min + hysteresis) OR above (max) for safety
    if (temp < settings.tempMin) {
        if (!_relays.getHeaterState()) {
            _relays.setHeater(true);
            Serial.println("Auto: Heater ON");
        }
    } else if (temp > (settings.tempMin + settings.hysteresis) || temp > settings.tempMax) {
        if (_relays.getHeaterState()) {
            _relays.setHeater(false);
            Serial.println("Auto: Heater OFF");
        }
    }

    // Fan Logic (High Temp)
    // Turn ON if above (max + hysteresis)
    // Turn OFF if below (max)
    if (temp > (settings.tempMax + settings.hysteresis)) {
        if (!_relays.getFanState()) {
            _relays.setFan(true);
            Serial.println("Auto: Fan ON (Temp High)");
        }
    } else if (temp < settings.tempMax) {
        // Fan OFF Logic
        // Fan should be OFF if Temp is below max.
        // (Humidity check removed as Fan is now decoupled from humidity)
        
        if (_relays.getFanState()) {
            _relays.setFan(false);
            Serial.println("Auto: Fan OFF");
        }
    }
}

void AutomationEngine::checkHumidity() {
    float humid = _sensor.getHumidity();
    SystemSettings settings = _settings.getSettings();

    if (isnan(humid)) return;

    // Debugging (Every 3 seconds)
    static unsigned long lastHumidDebug = 0;
    if (millis() - lastHumidDebug > 3000) {
        lastHumidDebug = millis();
        Serial.printf("[Auto] Humid: %.1f %% | Target Min: %.1f %% | Humidifier: %s\n", 
            humid, settings.humidMin, _relays.getHumidifierState() ? "ON" : "OFF");
    }

    // Humidifier Logic (Low Humidity)
    if (humid < settings.humidMin) {
        if (!_relays.getHumidifierState()) {
            _relays.setHumidifier(true);
            Serial.println("Auto: Humidifier ON");
        }
    } else if (humid > (settings.humidMin + settings.hysteresis) || humid > settings.humidMax) {
        if (_relays.getHumidifierState()) {
            _relays.setHumidifier(false);
            Serial.println("Auto: Humidifier OFF");
        }
    }

    // Fan Logic (High Humidity)
    // REMOVED: User state "Fan is for circulation", so we don't use it to exhaust humidity.
    /*
    if (humid > (settings.humidMax + settings.hysteresis)) {
        if (!_relays.getFanState()) {
            _relays.setFan(true);
            Serial.println("Auto: Fan ON (Humidity High)");
        }
    } 
    */
}

void AutomationEngine::checkEggTurning() {
    SystemSettings settings = _settings.getSettings();
    unsigned long intervalMillis = settings.turnIntervalMinutes * 60000UL;

    if (millis() - _lastTurnTime >= intervalMillis) {
        _lastTurnTime = millis();
        _isServoExtended = !_isServoExtended; // Toggle state

        Serial.printf("Auto: Turning Eggs. State: %s\n", _isServoExtended ? "Extend" : "Retract");
        _servo.turnEggs(_isServoExtended, settings.servoExtendAngle, settings.servoRetractAngle);
    }
}
