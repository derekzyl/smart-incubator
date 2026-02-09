#ifndef NOTIFICATIONS_H
#define NOTIFICATIONS_H

#include <Arduino.h>
#include <WiFiClientSecure.h>
#include <UniversalTelegramBot.h>
#include "config.h"

class NotificationManager {
public:
    NotificationManager();
    void begin();
    void sendAlert(String message);
    void sendMessage(String message);
    void update(); // Check for messages or handle queue if needed

private:
    WiFiClientSecure client;
    UniversalTelegramBot* bot;
};

#endif // NOTIFICATIONS_H
