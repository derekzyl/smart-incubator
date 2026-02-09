#include "relays.h"

RelayController::RelayController() : fanState(false), heaterState(false), humidifierState(false) {}

void RelayController::begin() {
    // Initialize pins as OUTPUT
    pinMode(PIN_RELAY_FAN, OUTPUT);
    pinMode(PIN_RELAY_HEATER, OUTPUT);
    pinMode(PIN_RELAY_HUMID, OUTPUT);
    
    // Initialize relays to OFF state
    digitalWrite(PIN_RELAY_FAN, RELAY_OFF);
    digitalWrite(PIN_RELAY_HEATER, RELAY_OFF);
    digitalWrite(PIN_RELAY_HUMID, RELAY_OFF);
}

void RelayController::setFan(bool state) {
    fanState = state;
    digitalWrite(PIN_RELAY_FAN, state ? RELAY_ON : RELAY_OFF);
}

void RelayController::setHeater(bool state) {
    heaterState = state;
    digitalWrite(PIN_RELAY_HEATER, state ? RELAY_ON : RELAY_OFF);
}

void RelayController::setHumidifier(bool state) {
    humidifierState = state;
    digitalWrite(PIN_RELAY_HUMID, state ? RELAY_ON : RELAY_OFF);
}

bool RelayController::getFanState() {
    return fanState;
}

bool RelayController::getHeaterState() {
    return heaterState;
}

bool RelayController::getHumidifierState() {
    return humidifierState;
}
