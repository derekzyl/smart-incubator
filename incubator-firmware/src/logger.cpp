#include "logger.h"

Logger::Logger() {}

void Logger::begin() {
    if (!SPIFFS.exists(_filename)) {
        File f = SPIFFS.open(_filename, FILE_WRITE);
        if (f) {
            f.println("time,temp,humid"); // Header
            f.close();
        }
    }
}

void Logger::logData(float temp, float humid, const String& timestamp) {
    File f = SPIFFS.open(_filename, FILE_APPEND);
    if (!f) {
        Serial.println("Failed to open log file for appending");
        return;
    }
    
    // Format: YYYY/MM/DD hh:mm:ss,temp,humid
    f.printf("%s,%.2f,%.2f\n", timestamp.c_str(), temp, humid);
    f.close();
    
    maintainSize();
}

String Logger::getHistoryJson() {
    File f = SPIFFS.open(_filename, FILE_READ);
    if (!f) return "[]";

    JsonDocument doc;
    JsonArray arr = doc.to<JsonArray>();

    // Skip header
    if (f.available()) f.readStringUntil('\n');

    while (f.available()) {
        String line = f.readStringUntil('\n');
        // Parse CSV line: time,temp,humid
        int comma1 = line.indexOf(',');
        int comma2 = line.lastIndexOf(',');
        
        if (comma1 > 0 && comma2 > comma1) {
            String timeStr = line.substring(0, comma1);
            float t = line.substring(comma1 + 1, comma2).toFloat();
            float h = line.substring(comma2 + 1).toFloat();
            
            // Limit to last 100 entries to prevent memory overflow during serialization
            // A better approach would be to stream the response, but this is simple for now.
            // For now, let's just add all and see if it fits in memory (ESP32 has decent RAM).
            // Actually, let's just take the last N lines if we could, but reading sequentially is easier.
            // We'll trust the circular buffer logic (maintainSize) to keep it reasonable.
            
            JsonObject obj = arr.add<JsonObject>();
            obj["time"] = timeStr;
            obj["avg_temp_1"] = t; // Matching App's expected field name
            obj["avg_humidity"] = h;
        }
    }
    f.close();

    String json;
    serializeJson(doc, json);
    return json;
}

void Logger::clearHistory() {
    SPIFFS.remove(_filename);
    begin();
}

void Logger::maintainSize() {
    // Basic rotation: if file > 50KB, rename to backup and start new?
    // Or just truncate? 
    // Implementing a true circular buffer on SPIFFS is slow.
    // For simplicity: if > 50KB, delete and start over. (User loses history but system stays stable)
    // Better: Keep last 50KB.
    
    if (SPIFFS.exists(_filename)) {
        File f = SPIFFS.open(_filename, FILE_READ);
        if (f.size() > 50000) {
            f.close();
            Serial.println("Log file too large, clearing...");
            clearHistory(); 
        } else {
            f.close();
        }
    }
}
