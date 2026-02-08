#ifndef RELAYS_H
#define RELAYS_H

#include <Arduino.h>
#include "config.h"

class RelayController {
public:
    RelayController();
    void begin();
    void setFan(bool state);
    void setHeater(bool state);
    void setHumidifier(bool state);
    
    bool getFanState();
    bool getHeaterState();
    bool getHumidifierState();

private:
    bool fanState;
    bool heaterState;
    bool humidifierState;
};

#endif // RELAYS_H
