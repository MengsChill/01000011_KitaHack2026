/*
  POLE AI Camera - FIXED & STABLE
  Hardware: ESP32-S3-N16R8 | OV3660
  currently output to Blynk 
*/

#define BLYNK_MAX_SENDBYTES 1200 
#define BLYNK_TEMPLATE_ID "TMPL62jRU9Iz3"
#define BLYNK_TEMPLATE_NAME "POLE camera"
#define BLYNK_AUTH_TOKEN    "wNIy4cZTpT_9rQBmnBO-h6BZ3qD55KCg" //fuck create new one :/

#include <WiFi.h>
#include <BlynkSimpleEsp32_SSL.h>
#include <HTTPClient.h>
#include <WiFiClientSecure.h>
#include <ArduinoJson.h>
#include "esp_camera.h"
#include "time.h"

const char* ssid     = "Hotspot name";
const char* password = "abcd1234";
const String apiKey  = "AIzaSyCgVjZzw5FXp29DOHtY36cRHFcmCd8CzdQ";
const String apiUrl  = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=" + apiKey;

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

void AnalyzeImage(String base64Image) {
  WiFiClientSecure client;
  client.setInsecure(); 
  HTTPClient http;
  
  if (http.begin(client, apiUrl)) {
    http.setTimeout(60000); 
    http.addHeader("Content-Type", "application/json");

    String jsonPayload = "{\"contents\": [{\"parts\": [";
    jsonPayload += "{\"text\": \"You are an AI walking stick but don't mention that you are in the description. Describe the image (under 80 words). Split the image into Left, Middle, and Right. Read any text visible.\"},";
    jsonPayload += "{\"inlineData\": {\"mimeType\": \"image/jpeg\", \"data\": \"" + base64Image + "\"}}";
    jsonPayload += "]}]}";

    Serial.println("Gemini is thinking...");
    int httpCode = http.POST(jsonPayload);

    if (httpCode == HTTP_CODE_OK) {
      DynamicJsonDocument doc(4096); 
      deserializeJson(doc, http.getString());
      

      String description = doc["candidates"][0]["content"]["parts"][0]["text"];
      description.replace("**", ""); 
      description.replace("* ", "- "); 
      
      Serial.println("\n[AI Description]");
      Serial.println(description);

      Blynk.virtualWrite(V1, description); 
      Serial.println("[Blynk] Data sent to phone.");
      
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

  if (psramFound()) {
    Serial.printf("[Memory] PSRAM Ready: %d KB Free\n", ESP.getFreePsram() / 1024);
  } else {
    Serial.println("[Fatal] PSRAM Not Found.");
    while(1); 
  }

  pinMode(BUTTON_PIN, INPUT_PULLUP);

  Serial.println("[WiFi] Connecting...");
  Blynk.begin(BLYNK_AUTH_TOKEN, ssid, password);
  WiFi.setSleep(false); 

  configTime(0, 0, "pool.ntp.org");
  time_t now = time(nullptr);
  while (now < 100000) { delay(500); now = time(nullptr); }
  Serial.println("[Time] Synced!");

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

  Serial.println("[System] Ready.");
}

void loop() {
  Blynk.run(); 

  if (digitalRead(BUTTON_PIN) == LOW) {
    delay(200); 
    Serial.println("\n[Action] Capturing Image...");
    
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
