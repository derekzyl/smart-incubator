#include "stepper.h"

StepperController::StepperController() : stepper(AccelStepper::HALF4WIRE, PIN_STEPPER_IN1, PIN_STEPPER_IN3, PIN_STEPPER_IN2, PIN_STEPPER_IN4) {
    // Note: AccelStepper order for ULN2003 is usually IN1, IN3, IN2, IN4
}

void StepperController::begin() {
    stepper.setMaxSpeed(STEPPER_MAX_SPEED);
    stepper.setAcceleration(STEPPER_ACCEL);
}

void StepperController::update() {
    stepper.run();
}

void StepperController::moveToPosition(long position) {
    stepper.moveTo(position);
}

void StepperController::setSpeed(float speed) {
    stepper.setMaxSpeed(speed);
}

long StepperController::getCurrentPosition() {
    return stepper.currentPosition();
}

bool StepperController::isRunning() {
    return stepper.isRunning();
}

void StepperController::stop() {
    stepper.stop();
}
