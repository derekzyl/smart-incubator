#include "notifications.h"

NotificationManager::NotificationManager() {
    bot = new UniversalTelegramBot(TELEGRAM_BOT_TOKEN, client);
}

void NotificationManager::begin() {
    // Determine if we need CA cert. For simplicity/robustness in hobby projects, 
    // we often use setInsecure(). Ideally, use a cert.
    client.setInsecure(); 
    Serial.println("Notification Manager Initialized");
}

void NotificationManager::sendAlert(String message) {
    if (WiFi.status() != WL_CONNECTED) {
        Serial.println("Cannot send alert: No WiFi");
        return;
    }
    
    // Check if token is default
    if (String(TELEGRAM_BOT_TOKEN) == "YOUR_BOT_TOKEN") {
        Serial.println("Alert skipped: Telegram credentials not set.");
        return;
    }

    String msg = "⚠️ *Incubator Alert* ⚠️\n\n" + message;
    if (bot->sendMessage(TELEGRAM_CHAT_ID, msg, "Markdown")) {
        Serial.println("Alert sent to Telegram");
    } else {
        Serial.println("Failed to send alert");
    }
}

void NotificationManager::sendMessage(String message) {
    if (WiFi.status() != WL_CONNECTED) {
        Serial.println("Cannot send message: No WiFi");
        return;
    }
    
    // Check if token is default
    if (String(TELEGRAM_BOT_TOKEN) == "YOUR_BOT_TOKEN") {
        Serial.println("Message skipped: Telegram credentials not set.");
        return;
    }

    if (bot->sendMessage(TELEGRAM_CHAT_ID, message, "Markdown")) {
        Serial.println("Message sent to Telegram");
    } else {
        Serial.println("Failed to send message");
    }
}

void NotificationManager::update() {
    // Can handle incoming messages here (e.g. /status)
    // For now, we only push alerts.
}
