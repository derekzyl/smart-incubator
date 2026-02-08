#ifndef BUTTONS_H
#define BUTTONS_H

#include <Arduino.h>
#include "config.h"

class ButtonHandler {
public:
    ButtonHandler();
    void begin();
    bool isModeButtonPressed();
    bool isSetButtonPressed();
    void update(); // Call in loop for debounce logic if needed

private:
    // Simple state handling for now
    int lastModeState;
    int lastSetState;
    unsigned long lastDebounceTime;
    unsigned long debounceDelay;
};

#endif // BUTTONS_H
