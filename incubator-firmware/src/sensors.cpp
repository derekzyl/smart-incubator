#include "sensors.h"

EnvironmentSensor::EnvironmentSensor() : dht(PIN_DHT, DHT_TYPE), currentTemp(NAN), currentHumid(NAN), lastReadTime(0) {}

void EnvironmentSensor::begin() {
    dht.begin();
    if (!rtc.begin()) {
        Serial.println("Couldn't find RTC");
    }
    if (rtc.lostPower()) {
        Serial.println("RTC lost power, letting's set the time!");
        rtc.adjust(DateTime(F(__DATE__), F(__TIME__)));
    }
}

void EnvironmentSensor::update() {
    unsigned long currentMillis = millis();
    if (currentMillis - lastReadTime >= 2000) { // Read every 2 seconds
        lastReadTime = currentMillis;
        float t = dht.readTemperature();
        float h = dht.readHumidity();

        if (isnan(t) || isnan(h)) {
            Serial.println("Failed to read from DHT sensor!");
            // Do not return, keep old values or just log failure.
            // Better yet: if NAN, maybe set to 0 or some error state if critical?
            // For now, let's just NOT update currentTemp/Humid if it's NAN
            // effectively holding the last good value.
        } else {
            currentTemp = t;
            currentHumid = h;
        }
    }
}

float EnvironmentSensor::getTemperature() {
    return currentTemp;
}

float EnvironmentSensor::getHumidity() {
    return currentHumid;
}

String EnvironmentSensor::getDateTime() {
    DateTime now = rtc.now();
    char buf[] = "YYYY/MM/DD hh:mm:ss";
    return now.toString(buf);
}

DateTime EnvironmentSensor::now() {
    return rtc.now();
}

void EnvironmentSensor::setTime(unsigned long epoch) {
    rtc.adjust(DateTime(epoch)); // RTClib supports epoch
    Serial.printf("Time updated to epoch: %lu\n", epoch);
}
