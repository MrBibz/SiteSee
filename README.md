# SiteSee

> **"Where to see a Site, and some even hidden."**
> Built for the HackTheMountain, SiteSee is a location-aware photo-sharing platform designed with gamified progression, adaptive spatial privacy thresholds, and real-time proximity-based content unlocking.

---

## The Problem & Our Solution

Traditional photo-sharing apps suffer from content oversaturation, detached engagement, and rigid privacy choices. Users are rarely encouraged to physically explore environments, and location settings are binary: entirely public or entirely private.

**SiteSee re-engineers location sharing into an exploratory game:**

* **Proximity-Locked Content ("Hidden Sites"):** Content creators can hide photos in the physical world. Other users can only view the high-resolution photo and details when their real-time device coordinates are **within 15 meters** of the spot.
* **Exploration Gamification:** Every shared site earns experience points (XP). As users travel and post, they level up, turning urban exploration into an adventure.
* **Fluid Privacy Tiers:** Posts adapt natively to user context—supporting fully **Public**, proximity-bound **Hidden**, and secure **Private** vaults.

---

## Features

* **Interactive Exploration Radar Map:** Powered by OpenStreetMap and custom map layers, rendering custom, color-coded, real-time spatial indicators for different visibility styles.
* **Proximity Filter Engine:** Background evaluation architecture that loops every 3 seconds to measure geodesic distance ($\le 15\text{m}$) using high-accuracy device GPS tracking.
* **Dynamic Navigation Interface:** Smooth tab navigation with a custom frosted glass navigation bar that automatically intercepts layout callbacks (e.g., clicking a recent item on the dashboard instantly pans the map layer and pulls up the location context window).
* **Native Device Bridges:** Direct integration with native storage pipelines and hardware camera modules for lightning-fast image serialization and base64 parsing.
* **XP & Levelling Engine:** Custom live progress calculation tracking that tells the user exactly how much real-world discovery remains to reach the next tier.

---

## Architecture & Tech Stack

SiteSee uses a clean, decoupling layout pattern separating the presentation screens from underlying domain services:

* **Frontend Framework:** [Flutter](https://flutter.dev/) (Dart)
* **Map & Spatial System:** [Flutter Map](https://pub.dev/packages/flutter_map) & [Geolocator](https://pub.dev/packages/geolocator) (OpenStreetMap data)
* **Backend Services:** [Firebase Core](https://firebase.google.com/) (Identity & Cloud synchronization infrastructure)
* **Local Staging:** Custom Async Dart Services (Memory & Local Storage persistence)

### Directory Overview

```text
lib/
├── models/         # Pure data structures (SitePhoto, UserProfile)
├── services/       # Core business logic & persistence (PhotoService, ProfileService)
├── pages/          # Primary view scaffolds (HomePage, MapPage, PhotoPage, ProfilePage)
└── widgets/        # Reusable custom UI items, map markers, and design tokens (AppTheme)

```

---

## Quick Start & Installation

### Prerequisites

* Flutter SDK (`>= 3.0.0`)
* Android Studio / Xcode (for emulation/device running)
* Valid GPS permissions enabled on target runtime environment

### Steps

1. **Clone the repository:**
```bash
git clone https://github.com/your-username/site-see.git
cd site-see

```


2. **Install dependecies:**
```bash
flutter pub get

```


3. **Configure Firebase (Optional for Local Mode):**
   Ensure your local environment configuration is linked via the FlutterFire CLI, or supply an initialized `google-services.json` / `GoogleService-Info.plist`.
4. **Run the Application:**
```bash
flutter run

```



---

## 🎮 How to Demo the App (Hackathon Track)

To experience the core proximity logic during static testing, we recommend utilizing an emulator capable of **GPS Mocking/Telemetry Injection**:

1. **The Dashboard:** Start on the *Accueil* tab to check out your current level status and view the most recent global publications.
2. **Snap a Site:** Move to the *Photo* tab. Capture or pick a picture, input a description, set visibility to **Hidden**, and tap publish. Your precise coordinates are automatically packaged with the image data.
3. **The Radar View:** Head over to the *Carte* tab. Your newly published site will appear on the map.
4. **Test Proximity Locking:** * Mock your device location to a distance **greater than 15 meters** away from your picture's coordinates. The point remains locked or conditionally hidden.
* Update your mocked GPS location back to **within 15 meters** of the pin. Within 3 seconds, the tracking engine triggers an update, making the marker fully interactive and allowing you to pop open the bottom context card.


5. **Quick Jump Validation:** Tap any item in the *Publications récentes* section on the home page—the app will programmatically switch tabs, animate the camera view over the target point, and automatically present the photo details panel.

---

## The Team

Built with love for the hackathon by:

* **Nicolas Bibeau** 
* **Hamza Gharbi**
* **Jory Trabajada**

---

*SiteSee — Re-discovering the world around you, one hidden site at a time.*
