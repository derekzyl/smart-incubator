#ifndef LOGGER_H
#define LOGGER_H

#include <Arduino.h>
#include <SPIFFS.h>
#include <ArduinoJson.h>

class Logger {
public:
    Logger();
    void begin();
    void logData(float temp, float humid, const String& timestamp);
    String getHistoryJson(); // Returns JSON array string
    void clearHistory();

private:
    const char* _filename = "/history.csv";
    void maintainSize(); // Keep file size in check
};

#endif
