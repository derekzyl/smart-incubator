#ifndef STORAGE_H
#define STORAGE_H

#include <Arduino.h>
#include <Preferences.h>
#include "config.h"

struct SystemSettings {
    float tempMin;
    float tempMax;
    float humidMin;
    float humidMax;
    float hysteresis;
    bool useCelsius;
};

class SettingsManager {
public:
    SettingsManager();
    void begin();
    
    void saveSettings(const SystemSettings& settings);
    SystemSettings getSettings();
    void loadSettings(); // Loads from NVS to local cache
    
    // Individual setters for convenience (will save to NVS)
    void setTempMin(float v);
    void setTempMax(float v);
    void setHumidMin(float v);
    void setHumidMax(float v);
    void setHysteresis(float v);

private:
    Preferences preferences;
    SystemSettings currentSettings;
    void save(); // Helper to save currentSettings to NVS
};

#endif // STORAGE_H
