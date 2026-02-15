#ifndef SENSORS_H
#define SENSORS_H

#include <Arduino.h>
#include <DHT.h>
#include <RTClib.h>
#include "config.h"

class EnvironmentSensor {
public:
    EnvironmentSensor();
    void begin();
    void update();
    float getTemperature();
    float getHumidity();
    String getDateTime();
    DateTime now();
    void setTime(unsigned long epoch);

private:
    DHT dht;
    RTC_DS3231 rtc;
    float currentTemp;
    float currentHumid;
    unsigned long lastReadTime;
};

#endif // SENSORS_H
