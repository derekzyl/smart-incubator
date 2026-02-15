#include "storage.h"

SettingsManager::SettingsManager() {}

void SettingsManager::begin() {
    preferences.begin("env-control", false); // Namespace "env-control", read-only = false
    loadSettings();
}

void SettingsManager::loadSettings() {
    // Load values, using defaults from config.h if not found
    currentSettings.tempMin = preferences.getFloat("tempMin", DEFAULT_TEMP_MIN);
    currentSettings.tempMax = preferences.getFloat("tempMax", DEFAULT_TEMP_MAX);
    currentSettings.humidMin = preferences.getFloat("humidMin", DEFAULT_HUMID_MIN);
    currentSettings.humidMax = preferences.getFloat("humidMax", DEFAULT_HUMID_MAX);
    currentSettings.hysteresis = preferences.getFloat("hysteresis", DEFAULT_HYSTERESIS);
    currentSettings.useCelsius = preferences.getBool("useCelsius", true);
    currentSettings.servoExtendAngle = preferences.getInt("sExt", DEFAULT_SERVO_EXTEND);
    currentSettings.servoRetractAngle = preferences.getInt("sRet", DEFAULT_SERVO_RETRACT);
    currentSettings.turnIntervalMinutes = preferences.getInt("tInt", DEFAULT_TURN_INTERVAL);
    currentSettings.incubationStartDate = preferences.getULong("startDate", 0);
    
    Serial.println("Settings loaded:");
    Serial.printf("Temp Min: %.1f, Max: %.1f\n", currentSettings.tempMin, currentSettings.tempMax);
    Serial.printf("Humid Min: %.1f, Max: %.1f\n", currentSettings.humidMin, currentSettings.humidMax);
    Serial.printf("Servo Ext: %d, Ret: %d, Int: %d\n", currentSettings.servoExtendAngle, currentSettings.servoRetractAngle, currentSettings.turnIntervalMinutes);
    Serial.printf("Start Date: %lu\n", currentSettings.incubationStartDate);
}

SystemSettings SettingsManager::getSettings() {
    return currentSettings;
}

void SettingsManager::saveSettings(const SystemSettings& settings) {
    currentSettings = settings;
    save();
}

void SettingsManager::save() {
    preferences.putFloat("tempMin", currentSettings.tempMin);
    preferences.putFloat("tempMax", currentSettings.tempMax);
    preferences.putFloat("humidMin", currentSettings.humidMin);
    preferences.putFloat("humidMax", currentSettings.humidMax);
    preferences.putFloat("hysteresis", currentSettings.hysteresis);
    preferences.putBool("useCelsius", currentSettings.useCelsius);
    preferences.putInt("sExt", currentSettings.servoExtendAngle);
    preferences.putInt("sRet", currentSettings.servoRetractAngle);
    preferences.putInt("tInt", currentSettings.turnIntervalMinutes);
    preferences.putULong("startDate", currentSettings.incubationStartDate);
    Serial.println("Settings saved to NVS.");
}

void SettingsManager::setTempMin(float v) {
    currentSettings.tempMin = v;
    preferences.putFloat("tempMin", v);
}

void SettingsManager::setTempMax(float v) {
    currentSettings.tempMax = v;
    preferences.putFloat("tempMax", v);
}

void SettingsManager::setHumidMin(float v) {
    currentSettings.humidMin = v;
    preferences.putFloat("humidMin", v);
}

void SettingsManager::setHumidMax(float v) {
    currentSettings.humidMax = v;
    preferences.putFloat("humidMax", v);
}

void SettingsManager::setHysteresis(float v) {
    currentSettings.hysteresis = v;
    preferences.putFloat("hysteresis", v);
}

void SettingsManager::setIncubationStartDate(unsigned long v) {
    currentSettings.incubationStartDate = v;
    preferences.putULong("startDate", v);
}
