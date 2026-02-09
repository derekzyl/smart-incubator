#ifndef WIFI_MANAGER_H
#define WIFI_MANAGER_H

#include <Arduino.h>
#include <WiFi.h>
#include "config.h"

class WifiManager {
public:
    WifiManager();
    void begin();
    void update(); // Handle reconnection
    bool isConnected();
    String getIP();
    int getRSSI();

private:
    unsigned long lastReconnectAttempt;
    unsigned long reconnectInterval;
    bool _connected;
};

#endif // WIFI_MANAGER_H
