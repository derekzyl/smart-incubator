#include "display.h"

DisplayController::DisplayController() : lcd(0x27, 20, 4) {} // Default address 0x27, 20x4 display

void DisplayController::begin() {
    lcd.init();
    lcd.backlight();
    lcd.setCursor(0, 0);
    lcd.print("System Initializing");
    delay(1000);
    lcd.clear();
}

void DisplayController::update(float temp, float humid, const String& time, bool fan, bool heater, bool humidState, const String& mode) {
    // Line 1: Temp & Humid
    lcd.setCursor(0, 0);
    lcd.print("T:");
    lcd.print(temp, 1);
    lcd.print("C H:");
    lcd.print(humid, 0);
    lcd.print("%");

    // Line 2: Time
    lcd.setCursor(0, 1);
    lcd.print(time);

    // Line 3: Relay Status
    lcd.setCursor(0, 2);
    lcd.print("F:");
    lcd.print(fan ? "ON " : "OFF");
    lcd.print(" H:");
    lcd.print(heater ? "ON " : "OFF");

    // Line 4: Mode & Humidifier
    lcd.setCursor(0, 3);
    lcd.print("M:");
    lcd.print(mode);
    lcd.print(" U:");
    lcd.print(humidState ? "ON" : "OFF");
}

void DisplayController::showMessage(const String& line1, const String& line2) {
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print(line1);
    lcd.setCursor(0, 1);
    lcd.print(line2);
}
