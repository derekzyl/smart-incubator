#include "relays.h"

RelayController::RelayController() : fanState(false), heaterState(false), humidifierState(false) {}

void RelayController::begin() {
    pinMode(PIN_RELAY_FAN, OUTPUT);
    pinMode(PIN_RELAY_HEATER, OUTPUT);
    pinMode(PIN_RELAY_HUMID, OUTPUT);
    
    // Initialize relays to OFF (Assuming HIGH trigger, or adapt if LOW trigger)
    // Most relay modules are LOW trigger, so writing HIGH often turns them OFF.
    // Let's assume active HIGH for now, as spec doesn't say.
    // IF active LOW, we'd write HIGH to turn off.
    // User can adjust. Let's assume standard logic first: HIGH = ON.
    
    digitalWrite(PIN_RELAY_FAN, LOW);
    digitalWrite(PIN_RELAY_HEATER, LOW);
    digitalWrite(PIN_RELAY_HUMID, LOW);
}

void RelayController::setFan(bool state) {
    fanState = state;
    digitalWrite(PIN_RELAY_FAN, state ? HIGH : LOW);
}

void RelayController::setHeater(bool state) {
    heaterState = state;
    digitalWrite(PIN_RELAY_HEATER, state ? HIGH : LOW);
}

void RelayController::setHumidifier(bool state) {
    humidifierState = state;
    digitalWrite(PIN_RELAY_HUMID, state ? HIGH : LOW);
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
