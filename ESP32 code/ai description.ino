/*
 POLE AI Camera
 ESP32-S3-N16R8 OV3660
 Captures image on button press and describes via Gemini 2.5 Flash.
 */

#include <WiFi.h>
#include <HTTPClient.h>
#include <WiFiClientSecure.h>
#include <ArduinoJson.h>
#include "esp_camera.h"
#include "time.h"

//config
const char* ssid     = "";
const char* password = "";
const String apiKey  = "";
const String apiUrl  = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=" + apiKey;

//hardware pins
#define PWDN_GPIO_NUM -1
#define RESET_GPIO_NUM -1
#define XCLK_GPIO_NUM 15
#define SIOD_GPIO_NUM 4
#define SIOC_GPIO_NUM 5
#define Y9_GPIO_NUM 16
#define Y8_GPIO_NUM 17
#define Y7_GPIO_NUM 18
#define Y6_GPIO_NUM 12
#define Y5_GPIO_NUM 10
#define Y4_GPIO_NUM 8
#define Y3_GPIO_NUM 9
#define Y2_GPIO_NUM 11
#define VSYNC_GPIO_NUM 6
#define HREF_GPIO_NUM 7
#define PCLK_GPIO_NUM 13
#define BUTTON_PIN 0

//base64 encoder
String encodeImageToBase64(uint8_t* data, size_t length) {
  static const char* table = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
  String base64 = "";
  base64.reserve(((length + 2) / 3) * 4); 
  for (size_t i = 0; i < length; i += 3) {
    uint32_t val = (data[i] << 16) + (i + 1 < length ? data[i + 1] << 8 : 0) + (i + 2 < length ? data[i + 2] : 0);
    base64 += table[(val >> 18) & 0x3F];
    base64 += table[(val >> 12) & 0x3F];
    base64 += (i + 1 < length) ? table[(val >> 6) & 0x3F] : '=';
    base64 += (i + 2 < length) ? table[val & 0x3F] : '=';
  }
  return base64;
}

//api logic
void AnalyzeImage(String base64Image) {
  WiFiClientSecure client;
  client.setInsecure(); 
  HTTPClient http;
  
  if (http.begin(client, apiUrl)) {
    http.setTimeout(60000); 
    http.addHeader("Content-Type", "application/json");

    // Dynamic payload building
    String jsonPayload = "{\"contents\": [{\"parts\": [";
    jsonPayload += "{\"text\": \"What is in this image? Describe it thoroughly, if there is any text read the text.\"},";
    jsonPayload += "{\"inlineData\": {\"mimeType\": \"image/jpeg\", \"data\": \"" + base64Image + "\"}}";
    jsonPayload += "]}]}";

    Serial.println("Gemini is thinking...");
    int httpCode = http.POST(jsonPayload);

    if (httpCode == HTTP_CODE_OK) {
      DynamicJsonDocument doc(4096); 
      deserializeJson(doc, http.getString());
      const char* description = doc["candidates"][0]["content"]["parts"][0]["text"];
      Serial.println(description);
    } else {
      Serial.printf("API Error: %d\n", httpCode);
    }
    http.end();
  }
}

void setup() {
  Serial.begin(115200);
  delay(2000);
  Serial.println("\n[System] Initializing Hardware...");

  //verify PSRAM
  if (psramFound()) {
    Serial.printf("[Memory] PSRAM Ready: %d KB Free\n", ESP.getFreePsram() / 1024);
  } else {
    Serial.println("[Fatal] PSRAM Not Found. Check Tools > PSRAM > OPI.");
    while(1); 
  }

  pinMode(BUTTON_PIN, INPUT_PULLUP);

  //network setup
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) { delay(500); Serial.print("."); }
  Serial.println("\n[WiFi] Connected!");

  //time sync for SSL
  configTime(0, 0, "pool.ntp.org");
  time_t now = time(nullptr);
  while (now < 100000) { delay(500); now = time(nullptr); }
  Serial.println("[Time] Synced!");

  //camera config
  camera_config_t config;
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer = LEDC_TIMER_0;
  config.pin_d0 = Y2_GPIO_NUM; config.pin_d1 = Y3_GPIO_NUM; config.pin_d2 = Y4_GPIO_NUM;
  config.pin_d3 = Y5_GPIO_NUM; config.pin_d4 = Y6_GPIO_NUM; config.pin_d5 = Y7_GPIO_NUM;
  config.pin_d6 = Y8_GPIO_NUM; config.pin_d7 = Y9_GPIO_NUM; config.pin_xclk = XCLK_GPIO_NUM;
  config.pin_pclk = PCLK_GPIO_NUM; config.pin_vsync = VSYNC_GPIO_NUM; config.pin_href = HREF_GPIO_NUM;
  config.pin_sscb_sda = SIOD_GPIO_NUM; config.pin_sscb_scl = SIOC_GPIO_NUM;
  config.pin_pwdn = PWDN_GPIO_NUM; config.pin_reset = RESET_GPIO_NUM;
  config.xclk_freq_hz = 20000000;
  config.pixel_format = PIXFORMAT_JPEG;
  config.frame_size = FRAMESIZE_VGA;  
  config.jpeg_quality = 12;           
  config.fb_count = 1;                
  config.fb_location = CAMERA_FB_IN_PSRAM;
  config.grab_mode = CAMERA_GRAB_LATEST;

  if (esp_camera_init(&config) != ESP_OK) {
    Serial.println("[Fatal] Camera Init Failed.");
    ESP.restart();
  }

  sensor_t * s = esp_camera_sensor_get();
  if (s->id.PID == OV3660_PID) s->set_vflip(s, 1);

  Serial.println("[System] Ready. Press BOOT to analyze.");
}

void loop() {
  if (digitalRead(BUTTON_PIN) == LOW) {
    delay(200); // Debounce
    Serial.println("\n[Action] Capturing Image...");
    
    //clear sensor buffer
    for(int i=0; i<2; i++){
      camera_fb_t* temp = esp_camera_fb_get();
      if(temp) esp_camera_fb_return(temp);
    }

    camera_fb_t* fb = esp_camera_fb_get();
    if (!fb) { Serial.println("[Error] Capture Failed"); return; }

    Serial.printf("[Image] Captured %d KB\n", fb->len / 1024);
    AnalyzeImage(encodeImageToBase64(fb->buf, fb->len));
    
    esp_camera_fb_return(fb); 
    Serial.println("[System] Standing by...");
  }
}
