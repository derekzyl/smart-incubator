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

void DisplayController::update(float temp, float humid, const String& time, bool fan, bool heater, bool humidState, const String& mode, const String& ip) {
    // Line 1: Temp & Humid
    lcd.setCursor(0, 0);
    lcd.print("T:"); 
    lcd.print(temp, 1);
    lcd.print("C H:");
    lcd.print(humid, 0);
    lcd.print("%    "); // Simple padding

    // Line 2: Time
    lcd.setCursor(0, 1);
    lcd.print(time);
    lcd.print("          "); // Padding

    // Line 3: Relay Status
    lcd.setCursor(0, 2);
    lcd.print("F:");
    lcd.print(fan ? "ON " : "OFF");
    lcd.print(" H:");
    lcd.print(heater ? "ON " : "OFF");
    lcd.print("   "); // Padding

    // Line 4: Mode/IP (Cycle every 3s)
    static unsigned long lastToggle = 0;
    static bool showIp = false;
    if (millis() - lastToggle > 3000) {
        lastToggle = millis();
        showIp = !showIp;
        lcd.setCursor(0, 3);
        lcd.print("                    "); // Clear line
    }

    lcd.setCursor(0, 3);
    if (showIp && ip != "0.0.0.0") {
        lcd.print(ip);
    } else {
        lcd.print("M:");
        lcd.print(mode);
        lcd.print(" U:");
        lcd.print(humidState ? "ON " : "OFF");
    }
}

void DisplayController::showMessage(const String& line1, const String& line2) {
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print(line1);
    lcd.setCursor(0, 1);
    lcd.print(line2);
}
