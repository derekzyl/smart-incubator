/*
 * Smart Incubator Controller
 * ESP32-based precision egg incubator with automatic turning
 */

#include <Arduino.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#include <Adafruit_SHT31.h>
#include <RTClib.h>
#include <AccelStepper.h>
#include <PID_v1.h>
#include <time.h>

// ==================== PIN DEFINITIONS ====================
// Temperature Sensors
#define ONE_WIRE_BUS 4          // DS18B20 sensors on GPIO4
#define SHT31_SDA 21            // I2C SDA
#define SHT31_SCL 22            // I2C SCL

// Control Outputs
#define HEATER_PIN 25           // SSR control for heater
#define FAN_PIN 26              // PWM fan control
#define HUMIDIFIER_PIN 27       // Relay for mist maker
#define BUZZER_PIN 14           // Piezo buzzer

// Stepper Motor
#define STEP_PIN 32
#define DIR_PIN 33
#define ENABLE_PIN 13

// Status LEDs
#define LED_HEATER 2
#define LED_HUMIDIFIER 12
#define LED_STATUS 15

// ==================== CONFIGURATION ====================
// WiFi credentials (update these)
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";

// API endpoint
const char* apiUrl = "http://YOUR_SERVER_IP:8000/api/v1/sensors/upload";
const char* incubatorId = "demo-incubator-1";  // Update with your incubator ID

// Control parameters
double targetTemp = 37.5;        // Target temperature (°C)
double targetHumidity = 55.0;    // Target humidity (%)
int turnIntervalHours = 4;       // Hours between turns
int turnAngle = 45;              // Degrees to turn eggs

// ==================== GLOBAL OBJECTS ====================
OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature sensors(&oneWire);
Adafruit_SHT31 sht31 = Adafruit_SHT31();
RTC_DS3231 rtc;

// Stepper motor (DRIVER mode)
AccelStepper stepper(AccelStepper::DRIVER, STEP_PIN, DIR_PIN);

// PID Controller
double pidInput, pidOutput, pidSetpoint;
PID myPID(&pidInput, &pidOutput, &pidSetpoint, 2.0, 5.0, 1.0, DIRECT);

// ==================== STATE VARIABLES ====================
struct SensorReadings {
  float temp1 = 0.0;      // DS18B20 #1
  float temp2 = 0.0;      // DS18B20 #2
  float tempSHT31 = 0.0;  // SHT31 temperature
  float humiditySHT31 = 0.0;
  bool heaterState = false;
  bool humidifierState = false;
  int fanSpeed = 50;      // 0-100%
};

SensorReadings currentReadings;
unsigned long lastSensorRead = 0;
unsigned long lastDataUpload = 0;
unsigned long lastTurnTime = 0;
bool lastTurnDirection = false;  // false = left, true = right
int stepperPosition = 0;
const int stepsPerTurn = 200;   // Steps for one full rotation (adjust based on gearing)

// ==================== FUNCTION DECLARATIONS ====================
void setupWiFi();
void readSensors();
void controlTemperature();
void controlHumidity();
void checkTurnSchedule();
void turnEggs(int angle);
void uploadSensorData();
void soundAlarm(int duration);
bool connectWiFi();

// ==================== SETUP ====================
void setup() {
  Serial.begin(115200);
  delay(1000);
  
  Serial.println("Smart Incubator Controller Starting...");
  
  // Initialize GPIO pins
  pinMode(HEATER_PIN, OUTPUT);
  pinMode(FAN_PIN, OUTPUT);
  pinMode(HUMIDIFIER_PIN, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(LED_HEATER, OUTPUT);
  pinMode(LED_HUMIDIFIER, OUTPUT);
  pinMode(LED_STATUS, OUTPUT);
  
  digitalWrite(HEATER_PIN, LOW);
  digitalWrite(HUMIDIFIER_PIN, LOW);
  digitalWrite(FAN_PIN, LOW);
  analogWrite(FAN_PIN, 128);  // Start fan at 50%
  
  // Initialize I2C
  Wire.begin(SHT31_SDA, SHT31_SCL);
  
  // Initialize RTC
  if (!rtc.begin()) {
    Serial.println("Couldn't find RTC");
    while (1) delay(10);
  }
  
  if (rtc.lostPower()) {
    Serial.println("RTC lost power, setting time");
    rtc.adjust(DateTime(F(__DATE__), F(__TIME__)));
  }
  
  // Initialize DS18B20 sensors
  sensors.begin();
  int deviceCount = sensors.getDeviceCount();
  Serial.print("Found ");
  Serial.print(deviceCount);
  Serial.println(" DS18B20 sensors");
  
  if (deviceCount < 2) {
    Serial.println("Warning: Expected 2 DS18B20 sensors, found fewer");
  }
  
  // Initialize SHT31
  if (!sht31.begin(0x44)) {
    Serial.println("Couldn't find SHT31");
    // Continue anyway, will use DS18B20 only
  } else {
    Serial.println("SHT31 initialized");
  }
  
  // Initialize stepper motor
  pinMode(ENABLE_PIN, OUTPUT);
  digitalWrite(ENABLE_PIN, LOW);  // Enable motor
  stepper.setMaxSpeed(1000);      // Steps per second
  stepper.setAcceleration(500);   // Steps per second^2
  stepper.setCurrentPosition(0);
  
  // Initialize PID controller
  pidSetpoint = targetTemp;
  myPID.SetMode(AUTOMATIC);
  myPID.SetOutputLimits(0, 255);  // PWM range
  myPID.SetSampleTime(5000);      // Update every 5 seconds
  
  // Connect to WiFi
  setupWiFi();
  
  // Initial sensor reading
  readSensors();
  
  // Record initial turn time
  lastTurnTime = millis();
  
  Serial.println("Setup complete!");
  digitalWrite(LED_STATUS, HIGH);
}

// ==================== MAIN LOOP ====================
void loop() {
  unsigned long currentMillis = millis();
  
  // Read sensors every 5 seconds
  if (currentMillis - lastSensorRead >= 5000) {
    readSensors();
    lastSensorRead = currentMillis;
    
    // Control systems
    controlTemperature();
    controlHumidity();
    
    // Check for alarms
    if (currentReadings.tempSHT31 < 35.0 || currentReadings.tempSHT31 > 40.0) {
      soundAlarm(1000);
    }
  }
  
  // Upload data to API every 30 seconds
  if (currentMillis - lastDataUpload >= 30000) {
    if (WiFi.status() == WL_CONNECTED) {
      uploadSensorData();
    } else {
      connectWiFi();
    }
    lastDataUpload = currentMillis;
  }
  
  // Check turn schedule every minute
  if (currentMillis - lastTurnTime >= 60000) {
    checkTurnSchedule();
  }
  
  // Run stepper motor if needed
  stepper.run();
  
  delay(100);  // Small delay to prevent watchdog issues
}

// ==================== SENSOR READING ====================
void readSensors() {
  // Request temperatures from DS18B20
  sensors.requestTemperatures();
  
  // Read DS18B20 sensors
  currentReadings.temp1 = sensors.getTempCByIndex(0);
  if (sensors.getDeviceCount() > 1) {
    currentReadings.temp2 = sensors.getTempCByIndex(1);
  } else {
    currentReadings.temp2 = currentReadings.temp1;  // Use same reading
  }
  
  // Read SHT31
  if (sht31.isHeaterEnabled()) {
    sht31.heater(false);  // Disable heater for normal operation
  }
  
  currentReadings.tempSHT31 = sht31.readTemperature();
  currentReadings.humiditySHT31 = sht31.readHumidity();
  
  // Validate readings
  if (isnan(currentReadings.tempSHT31)) {
    currentReadings.tempSHT31 = (currentReadings.temp1 + currentReadings.temp2) / 2.0;
  }
  if (isnan(currentReadings.humiditySHT31)) {
    currentReadings.humiditySHT31 = 55.0;  // Default
  }
  
  // Print to serial
  Serial.print("Temp1: ");
  Serial.print(currentReadings.temp1);
  Serial.print("°C, Temp2: ");
  Serial.print(currentReadings.temp2);
  Serial.print("°C, TempSHT31: ");
  Serial.print(currentReadings.tempSHT31);
  Serial.print("°C, Humidity: ");
  Serial.print(currentReadings.humiditySHT31);
  Serial.println("%");
}

// ==================== TEMPERATURE CONTROL (PID) ====================
void controlTemperature() {
  // Use average of DS18B20 sensors as PID input
  pidInput = (currentReadings.temp1 + currentReadings.temp2) / 2.0;
  pidSetpoint = targetTemp;
  
  // Compute PID
  myPID.Compute();
  
  // Control heater with PWM (SSR)
  int heaterPWM = (int)pidOutput;
  analogWrite(HEATER_PIN, heaterPWM);
  currentReadings.heaterState = (heaterPWM > 50);  // Consider "on" if >20% duty cycle
  
  digitalWrite(LED_HEATER, currentReadings.heaterState ? HIGH : LOW);
  
  // Control fan speed based on temperature
  if (pidInput > targetTemp + 0.5) {
    currentReadings.fanSpeed = 100;  // Full speed if too hot
  } else if (pidInput < targetTemp - 0.5) {
    currentReadings.fanSpeed = 30;   // Low speed if too cold
  } else {
    currentReadings.fanSpeed = 50;   // Medium speed
  }
  analogWrite(FAN_PIN, map(currentReadings.fanSpeed, 0, 100, 0, 255));
  
  Serial.print("PID Output: ");
  Serial.print(pidOutput);
  Serial.print(", Heater PWM: ");
  Serial.println(heaterPWM);
}

// ==================== HUMIDITY CONTROL ====================
void controlHumidity() {
  // Simple on/off control with hysteresis
  if (currentReadings.humiditySHT31 < targetHumidity - 5.0) {
    digitalWrite(HUMIDIFIER_PIN, HIGH);
    currentReadings.humidifierState = true;
    digitalWrite(LED_HUMIDIFIER, HIGH);
  } else if (currentReadings.humiditySHT31 > targetHumidity + 5.0) {
    digitalWrite(HUMIDIFIER_PIN, LOW);
    currentReadings.humidifierState = false;
    digitalWrite(LED_HUMIDIFIER, LOW);
  }
}

// ==================== EGG TURNING ====================
void checkTurnSchedule() {
  DateTime now = rtc.now();
  
  // Check if it's time to turn (every N hours)
  int hoursSinceLastTurn = (millis() - lastTurnTime) / (turnIntervalHours * 3600000);
  
  if (hoursSinceLastTurn >= 1 || lastTurnTime == 0) {
    Serial.println("Time to turn eggs!");
    turnEggs(turnAngle);
    lastTurnTime = millis();
  }
}

void turnEggs(int angle) {
  Serial.print("Turning eggs ");
  Serial.print(angle);
  Serial.println(" degrees");
  
  // Calculate steps needed (adjust based on your mechanical setup)
  // Assuming 1.8° per step motor, with gearing ratio
  // For 45° turn with 1:1 gearing: 45 / 1.8 = 25 steps
  // Adjust this calculation based on your actual setup
  int steps = (angle * stepsPerTurn) / 360;
  
  // Alternate direction
  lastTurnDirection = !lastTurnDirection;
  stepper.moveTo(lastTurnDirection ? steps : -steps);
  
  // Wait for movement to complete
  while (stepper.distanceToGo() != 0) {
    stepper.run();
    delay(10);
  }
  
  // Return to center after a delay (optional, for some designs)
  delay(1000);
  stepper.moveTo(0);
  while (stepper.distanceToGo() != 0) {
    stepper.run();
    delay(10);
  }
  
  // Record turn event (upload to API)
  recordTurnEvent(angle);
}

void recordTurnEvent(int angle) {
  if (WiFi.status() != WL_CONNECTED) {
    return;
  }
  
  HTTPClient http;
  http.begin(String(apiUrl).replace("/sensors/upload", "/turns/record"));
  http.addHeader("Content-Type", "application/json");
  
  StaticJsonDocument<200> doc;
  doc["incubator_id"] = incubatorId;
  doc["angle_degrees"] = angle;
  doc["duration_seconds"] = 5;  // Approximate
  
  String payload;
  serializeJson(doc, payload);
  
  int httpResponseCode = http.POST(payload);
  http.end();
  
  Serial.print("Turn event recorded: ");
  Serial.println(httpResponseCode);
}

// ==================== DATA UPLOAD ====================
void uploadSensorData() {
  if (WiFi.status() != WL_CONNECTED) {
    return;
  }
  
  HTTPClient http;
  http.begin(apiUrl);
  http.addHeader("Content-Type", "application/json");
  
  StaticJsonDocument<500> doc;
  doc["incubator_id"] = incubatorId;
  doc["temp_1"] = currentReadings.temp1;
  doc["temp_2"] = currentReadings.temp2;
  doc["temp_sht31"] = currentReadings.tempSHT31;
  doc["humidity_sht31"] = currentReadings.humiditySHT31;
  doc["heater_state"] = currentReadings.heaterState;
  doc["humidifier_state"] = currentReadings.humidifierState;
  doc["fan_speed"] = currentReadings.fanSpeed;
  doc["timestamp"] = rtc.now().unixtime();
  
  String payload;
  serializeJson(doc, payload);
  
  int httpResponseCode = http.POST(payload);
  
  if (httpResponseCode > 0) {
    String response = http.getString();
    Serial.print("Data uploaded: ");
    Serial.println(httpResponseCode);
  } else {
    Serial.print("Upload failed: ");
    Serial.println(httpResponseCode);
  }
  
  http.end();
}

// ==================== WIFI SETUP ====================
void setupWiFi() {
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);
  
  Serial.print("Connecting to WiFi");
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println();
    Serial.print("Connected! IP address: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println();
    Serial.println("WiFi connection failed");
  }
}

bool connectWiFi() {
  if (WiFi.status() == WL_CONNECTED) {
    return true;
  }
  
  WiFi.disconnect();
  delay(100);
  WiFi.begin(ssid, password);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 10) {
    delay(500);
    attempts++;
  }
  
  return (WiFi.status() == WL_CONNECTED);
}

// ==================== ALARM ====================
void soundAlarm(int duration) {
  for (int i = 0; i < 3; i++) {
    digitalWrite(BUZZER_PIN, HIGH);
    delay(duration);
    digitalWrite(BUZZER_PIN, LOW);
    delay(duration);
  }
}
