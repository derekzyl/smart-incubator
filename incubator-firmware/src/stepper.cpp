#include "stepper.h"

StepperController::StepperController() : stepper(AccelStepper::DRIVER, PIN_STEPPER_STEP, PIN_STEPPER_DIR) {}

void StepperController::begin() {
    stepper.setEnablePin(PIN_STEPPER_ENABLE);
    stepper.setPinsInverted(false, false, true); // Invert enable pin if needed (usually active LOW)
    stepper.enableOutputs();
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
