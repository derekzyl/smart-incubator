#ifndef DISPLAY_H
#define DISPLAY_H

#include <Arduino.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include "config.h"

class DisplayController {
public:
    DisplayController();
    void begin();
    void update(float temp, float humid, const String& time, bool fan, bool heater, bool humidState, const String& mode);
    void showMessage(const String& line1, const String& line2);

private:
    LiquidCrystal_I2C lcd;
};

#endif // DISPLAY_H
