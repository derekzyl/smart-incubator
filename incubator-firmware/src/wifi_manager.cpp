#include "wifi_manager.h"
#include <ESPmDNS.h>

WifiManager::WifiManager() : lastReconnectAttempt(0), reconnectInterval(10000), _connected(false) {}

// WifiManager::begin()
void WifiManager::begin() {
    WiFi.mode(WIFI_AP_STA); // Station + Access Point
    
    // Connect to Router
    WiFi.begin(WIFI_SSID, WIFI_PASS);
    Serial.printf("Connecting to WiFi SSID: %s\n", WIFI_SSID);

    // Create Hotspot
    WiFi.softAP(AP_SSID, AP_PASS);
    Serial.printf("Created Hotspot: %s\n", AP_SSID);
    Serial.print("AP IP Address: ");
    Serial.println(WiFi.softAPIP());
}

void WifiManager::update() {
    if (WiFi.status() == WL_CONNECTED) {
        if (!_connected) {
            _connected = true;
            Serial.println("\nWiFi Connected!");
            Serial.print("IP Address: ");
            Serial.println(WiFi.localIP());

            // Start mDNS
            if (MDNS.begin("incubator")) {
                Serial.println("mDNS responder started: http://incubator.local");
                MDNS.addService("http", "tcp", 80);
            } else {
                Serial.println("Error setting up mDNS responder!");
            }
        }
    } else {
        _connected = false;
        unsigned long currentMillis = millis();
        if (currentMillis - lastReconnectAttempt >= reconnectInterval) {
            lastReconnectAttempt = currentMillis;
            Serial.println("Reconnecting to WiFi...");
            WiFi.disconnect();
            WiFi.reconnect();
        }
    }
}

bool WifiManager::isConnected() {
    return WiFi.status() == WL_CONNECTED;
}

String WifiManager::getIP() {
    if (isConnected()) {
        return WiFi.localIP().toString();
    }
    return "0.0.0.0";
}

int WifiManager::getRSSI() {
    return WiFi.RSSI();
}
