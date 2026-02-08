#ifndef STEPPER_H
#define STEPPER_H

#include <Arduino.h>
#include <AccelStepper.h>
#include "config.h"

class StepperController {
public:
    StepperController();
    void begin();
    void update();
    void moveToPosition(long position);
    void setSpeed(float speed);
    long getCurrentPosition();
    bool isRunning();
    void stop();

private:
    AccelStepper stepper;
};

#endif // STEPPER_H
