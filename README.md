<br />
<div align="center">
    <img src="images/POLELogo.jpeg" alt="Logo" width="500" height="300">
  </a>

  <h3 align="center">POLE</h3>

  <p align="center">
    An AI assisted walking stick for the visually impaired    <br />
    <a href="https://github.com/MengsChill/01000011_KitaHack2026">View Demo</a>
    &middot;
    <a href="https://github.com/MengsChill/01000011_KitaHack2026/issues/new?labels=bug&template=bug-report---.md">Report Bug</a>
    &middot;
    <a href="https://github.com/MengsChill/01000011_KitaHack2026/issues/new?labels=enhancement&template=feature-request---.md">Request Feature</a>
  </p>
</div>

<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
      <ul>
        <li><a href="#built-with">Built With</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#roadmap">Roadmap</a></li>
    <li><a href="#contributors">Contributors</a></li>
  </ol>
</details>

## About The Project
<br/>
<div align="center">
    <img src="images/image.png" alt="product" width="300" height="1000">
  </a>
</div>

POLE innovates your basic old walking stick, designed to enhance mobility and independence for individuals with various physical challenges. Our smart walking cane provides users with a range of intelligent features and functionalities that revolutionise the traditional walking aid industry, such as obstacle detection with haptic feedback and descriptions with AI vision(eg. searching for dropped objects, reading from a menu, etc.) With these features, POLE enhances your daily journeys like never before. Stay connected and informed with real-time data such as distance travelled, weather updates and even live location services. Most importantly, always be alerted with the presence of obstacles via haptic feedback and a full detailed description of whats in front of you with a click of a button, providing a safer journey everywhere you go.

<p align="right">(<a href="#readme-top">back to top</a>)</p>



### Built With
* [![React][React.js]][React-url]
* [![Dart][Dart.dev]][Dart-url]
* [![Flutter][Flutter.dev]][Flutter-url]
* [![Firebase][Firebase.google.com]][Firebase-url]
* [! [Python] [Python.org]][Python-url]
* [![Shell][Shell.sh]][Shell-url]
* [! [YAML][YAML.org]] [YAML-url]
* [! [JSON] [JSON.org]] [JSON-url]
* [! [Markdown] [Markdown.org]] [Markdown-url]
* [! [Kotlin] [Kotlin.lang]] [Kotlin-url]
* [! [Java] [Java.com]][Java-url]

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Usage
Learn how to use the POLE with our [video demo.](https://youtube.com/)

Watch our [marketing video.](https://youtube.com/)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Roadmap

POLE is still a work in progress, help us by proposing features you would like to be seen implemented!

[Propose Features](https://github.com/MengsChill/01000011_KitaHack2026/issues/new?labels=enhancement&template=feature-request---.md)

- [x] Base model w/o AI integration
- [x] AI integration to give a detailed description
- [ ] Better app integration (currently using Blynk for AI description output :/)
- [ ] Text to speech locally
- [ ] Locally hosted AI to remove the reliance on internet
- [ ] Real Time AI object detection
- [ ] Integration with Google Maps and indoor positioning systems
- [ ] Real-time facial recognition of friends and family

See the [open issues](https://github.com/MengsChill/01000011_KitaHack2026/issues) for a full list of proposed features (and known issues).

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Getting Started

To get a local copy up and running, follow these steps to set up both the Hardware (ESP32) and the Mobile App.

###Hardware Setup (ESP32)
1.  **Open Code**: Open `ESP32 code/POLE.ino` in the **Arduino IDE**.
2.  **Dependencies**: Install `blynk` and `ArduinoJson` from the Library Manager.
3.  **Config**: Update your WiFi and API keys in the code:
    ```cpp
    const char* ssid = "YOUR_WIFI_NAME";
    const char* password = "YOUR_WIFI_PASSWORD";
    const String apiKey = "YOUR_GEMINI_API_KEY";
    ```
4.  **Flash**: Select **ESP32-S3 Dev Module**, enable **PSRAM**, and upload to your device.

###  Mobile App Setup
1.  **Clone the repo**
    ```sh
    git clone https://github.com/MengsChill/01000011_KitaHack2026.git
    cd smartstick_app
    ```
2.  **Install Dependencies**
    ```sh
    flutter pub get
    ```
3.  **Environment Setup**
    *   Create a [.env](cci:7://file:///Users/cm/smartstick_app/.env:0:0-0:0) file from [.env.example](cci:7://file:///Users/cm/smartstick_app/.env.example:0:0-0:0): `cp .env.example .env`
    *   Add your **Firebase** and **Weather** API keys to the [.env](cci:7://file:///Users/cm/smartstick_app/.env:0:0-0:0) file.
4.  **Firebase Config**
    *   Place [google-services.json](cci:7://file:///Users/cm/smartstick_app/android/app/google-services.json:0:0-0:0) in `android/app/`.
    *   Place `GoogleService-Info.plist` in `ios/Runner/`.
5.  **Run the app**
   
    Run on a connected device or emulator
    ```sh
    flutter run
    ```


### Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.10.4 or higher)
* [Dart SDK](https://dart.dev/get-started/sdk)
* A Firebase account

## 🛠️ Technical Implementation

POLE combines high-performance mobile development with edge AI and IoT to create a seamless assistive experience.

### Powered by Google Tools
*   **Flutter & Dart**: Cross-platform frontend for high-performance, consistent UI across iOS and Android.
*   **Gemini 1.5 Flash**: Orchestrates real-time image analysis directly on the hardware for lightning-fast obstacle description.
*   **Firebase Ecosystem**:
    *   **Authentication**: Secure user and caregiver login.
    *   **Cloud Firestore**: Real-time synchronization of stick status, GPS logs, and pairing data.
    *   **Firebase Storage**: Secure hosting for the AI-captured environment snapshots.
*   **Google Maps Platform**: Precise real-time tracking and location history visualization for caregivers.

### The Ecosystem
1.  **POLE (Edge AI)**: An **ESP32-S3** captures images which are processed by **Gemini 1.5 Flash** to generate natural language descriptions of the environment.
2.  **Communication (Blynk)**: Uses the Blynk IoT bridge to transmit hardware data (distance, AI descriptions, status) securely to the cloud.
3.  **The Mobile App**: A Flutter-based dashboard that aggregates sensor data, displays the Google Map, and provides real-time notifications and weather updates via **OpenWeather API**.
4.  **Caregiver Sync**: Real-time pairing system allows family members to monitor the user’s safety and location history instantly via Firestore listeners.

## Implementation, Innovation, and Challenges

### Innovation: AI on the Edge
Unlike traditional assistive tools that rely on a phone's camera, POLE brings **Edge AI** directly to the walking stick. By integrating **Gemini 1.5 Flash** with an **ESP32-S3**, we created a device that can "see" and "describe" the environment with human-like detail, providing a revolutionary level of independence for the visually impaired.

### Implementation Strategy
The project follows a modular architecture:
*   **Hardware Layer**: Low-level C++ code managing sensor interrupts and AI image capture.
*   **IoT Bridge**: A secure data tunnel using Blynk to ensure real-time communication without complex server management.
*   **Mobile Layer**: A Flutter app acting as a high-level control center for both the user and their caregiver.
*   **Security First**: Implementation of environment-based configuration for all sensitive API keys (Google Maps, Firebase, Weather).

### Challenges Faced & Overcome
1.  **Memory Constraints**: The ESP32-S3 has limited PSRAM. We optimized the AI image capture and encoding process to ensure high-quality images could be sent to Gemini without crashing the hardware.
2.  **Real-Time Data Sync**: To ensure caregiver tracking was accurate, we implemented a custom polling and Firestore listener system to balance battery life with real-time updates.
3.  **Security in Open Source**: We faced a challenge in keeping our private API keys secure for the hackathon. We overcame this by building a custom `.env` loading logic for our Flutter app and securing our `.gitignore`.

# Contributors
This project was a collaborative effort by the following members:
* **AI integration, ESP32 programming & Testing: Choong Jun Zac [GitHub](https://github.com/ishtardsama), [Email](noteethme@gmail.com)**
* **Mobile App development(Backend/Frontend Design), UX & Testing: Oh Chu Meng [GitHub](https://github.com/MengsChill)**
* **Electrical Engineering, Prototype Modeling & Testing: Teoh Yue Wen [GitHub](https://github.com/TealApples)**
* **Budget allocation, Finance, Marketing: Jaccob Chin Sing Hung(No Github 😢)**

<p align="right">(<a href="#readme-top">back to top</a>)</p>

[contributors-url]: https://github.com/MengsChill/01000011_KitaHack2026/graphs/contributors
[issues-url]: https://github.com/MengsChill/01000011_KitaHack2026/issues
[product-screenshot]: images/screenshot.png
[Dart.dev]: https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white
[Dart-url]: https://dart.dev/
[Flutter.dev]: https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white
[Flutter-url]: https://flutter.dev/
[Next.js]: https://img.shields.io/badge/next.js-000000?style=for-the-badge&logo=nextdotjs&logoColor=white
[Next-url]: https://nextjs.org/
[React.js]: https://img.shields.io/badge/React-20232A?style=for-the-badge&logo=react&logoColor=61DAFB
[React-url]: https://reactjs.org/
[Vue.js]: https://img.shields.io/badge/Vue.js-35495E?style=for-the-badge&logo=vuedotjs&logoColor=4FC08D
[Vue-url]: https://vuejs.org/
[Angular.io]: https://img.shields.io/badge/Angular-DD0031?style=for-the-badge&logo=angular&logoColor=white
[Angular-url]: https://angular.io/
[Svelte.dev]: https://img.shields.io/badge/Svelte-4A4A55?style=for-the-badge&logo=svelte&logoColor=FF3E00
[Svelte-url]: https://svelte.dev/
[Laravel.com]: https://img.shields.io/badge/Laravel-FF2D20?style=for-the-badge&logo=laravel&logoColor=white
[Laravel-url]: https://laravel.com
[Bootstrap.com]: https://img.shields.io/badge/Bootstrap-563D7C?style=for-the-badge&logo=bootstrap&logoColor=white
[Bootstrap-url]: https://getbootstrap.com
[JQuery.com]: https://img.shields.io/badge/jQuery-0769AD?style=for-the-badge&logo=jquery&logoColor=white
[JQuery-url]: https://jquery.com 
[Dart.dev]: https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white
[Dart-url]: https://dart.dev/
[Flutter.dev]: https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white
[Flutter-url]: https://flutter.dev/
[Firebase.google.com]: https://img.shields.io/badge/Firebase-039BE5?style=for-the-badge&logo=Firebase&logoColor=white
[Firebase-url]: https://firebase.google.com/
[Python.org]: https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white
[Python-url]: https://www.python.org/

[Shell.sh]: https://img.shields.io/badge/Shell_Script-121011?style=for-the-badge&logo=gnu-bash&logoColor=white
[Shell-url]: https://www.gnu.org/software/bash/

[YAML.org]: https://img.shields.io/badge/YAML-CB171E?style=for-the-badge&logo=yaml&logoColor=white
[YAML-url]: https://yaml.org/

[JSON.org]: https://img.shields.io/badge/JSON-000000?style=for-the-badge&logo=json&logoColor=white
[JSON-url]: https://www.json.org/

[Markdown.org]: https://img.shields.io/badge/Markdown-000000?style=for-the-badge&logo=markdown&logoColor=white
[Markdown-url]: https://www.markdownguide.org/

[Kotlin.lang]: https://img.shields.io/badge/Kotlin-7F52FF?style=for-the-badge&logo=kotlin&logoColor=white
[Kotlin-url]: https://kotlinlang.org/

[Java.com]: https://img.shields.io/badge/Java-ED8B00?style=for-the-badge&logo=openjdk&logoColor=white
[Java-url]: https://www.java.com/

