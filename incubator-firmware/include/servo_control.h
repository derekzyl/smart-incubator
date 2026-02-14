#ifndef SERVO_CONTROL_H
#define SERVO_CONTROL_H

#include <Arduino.h>
#include <ESP32Servo.h>
#include "config.h"

class ServoController {
public:
    ServoController();
    void begin();
    void moveToAngle(int angle);
    int getCurrentAngle();
    
    // Automation helper
    void turnEggs(bool extend); // true = 90 (extend), false = 0 (retract)

private:
    Servo myservo;
    int _currentAngle;
    int _servoPin;
};

#endif // SERVO_CONTROL_H
