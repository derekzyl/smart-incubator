#include "buttons.h"

ButtonHandler::ButtonHandler() : lastModeState(HIGH), lastSetState(HIGH), lastDebounceTime(0), debounceDelay(50) {}

void ButtonHandler::begin() {
    pinMode(PIN_BUTTON_MODE, INPUT_PULLUP);
    pinMode(PIN_BUTTON_SET, INPUT); // External pull-up as per spec, or use INPUT_PULLUP if internal is fine. module usually has pullup or we use internal.
    // Spec said "Button 2: 35 ... needs external 10kΩ pull-up". Pin 35 is input only, no internal pullup.
    // So we just use INPUT.
}

bool ButtonHandler::isModeButtonPressed() {
    int reading = digitalRead(PIN_BUTTON_MODE);
    if (reading == LOW) { // Active LOW
        delay(50); // Simple debounce
        if (digitalRead(PIN_BUTTON_MODE) == LOW) {
            while(digitalRead(PIN_BUTTON_MODE) == LOW); // Wait for release
            return true;
        }
    }
    return false;
}

bool ButtonHandler::isSetButtonPressed() {
    int reading = digitalRead(PIN_BUTTON_SET);
    // Assuming active LOW (button connects to ground) with external pull-up.
    if (reading == LOW) { 
        delay(50);
        if (digitalRead(PIN_BUTTON_SET) == LOW) {
            while(digitalRead(PIN_BUTTON_SET) == LOW);
            return true;
        }
    }
    return false;
}

void ButtonHandler::update() {
    // Implement more complex non-blocking debounce here if needed
}
