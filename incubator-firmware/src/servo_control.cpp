#include "servo_control.h"

ServoController::ServoController() : _currentAngle(0), _servoPin(PIN_SERVO) {
}

void ServoController::begin() {
    // Allow allocation of all timers
    ESP32PWM::allocateTimer(0);
    ESP32PWM::allocateTimer(1);
    ESP32PWM::allocateTimer(2);
    ESP32PWM::allocateTimer(3);
    
    myservo.setPeriodHertz(50); // Standard 50hz servo
    myservo.attach(_servoPin, 500, 2400); // Standard min/max pulse width
    
    // Initial position
    moveToAngle(DEFAULT_SERVO_RETRACT);
}

void ServoController::moveToAngle(int angle) {
    // Constrain angle
    if (angle < 0) angle = 0;
    if (angle > 180) angle = 180;
    
    myservo.write(angle);
    _currentAngle = angle;
}

int ServoController::getCurrentAngle() {
    return _currentAngle;
}

void ServoController::turnEggs(bool extend, int extendAngle, int retractAngle) {
    if (extend) {
        moveToAngle(extendAngle);
    } else {
        moveToAngle(retractAngle);
    }
}
