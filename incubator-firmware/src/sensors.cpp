#include "sensors.h"

EnvironmentSensor::EnvironmentSensor() : dht(PIN_DHT, DHT_TYPE), currentTemp(0.0), currentHumid(0.0), lastReadTime(0) {}

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
        float h = dht.readHumidity();
        float t = dht.readTemperature();

        if (isnan(h) || isnan(t)) {
            Serial.println(F("Failed to read from DHT sensor!"));
            return;
        }

        currentTemp = t;
        currentHumid = h;
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
