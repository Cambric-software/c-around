# C Around v1.0.3

> **The world, explained.** An offline accessibility companion for Android, Windows and Linux.

[![Release](https://img.shields.io/github/v/release/Cambric-software/c-around?label=latest)](https://github.com/Cambric-software/c-around/releases/latest)
[![Tests](https://github.com/Cambric-software/c-around/actions/workflows/ci.yml/badge.svg)](https://github.com/Cambric-software/c-around/actions/workflows/ci.yml)
[![License: Proprietary](https://img.shields.io/badge/license-Proprietary-red.svg)](LICENSE)

**Download page:** https://cambric-software.github.io/c-around/  
**Direct APK:** https://github.com/Cambric-software/c-around/releases/latest/download/android.apk

---

## What it does

C Around is an offline-first accessibility companion for people who are blind, have low vision, are deaf or hard-of-hearing, or are non-verbal. Every feature runs entirely on the device — no account, no cloud, no data upload.

| Feature | What it does | Works on Android |
|---|---|---|
| **Camera awareness** | YOLO detects hazards (cars, stairs, people) and speaks them with direction | ✅ Bundled |
| **Sound monitor** | YAMNet classifies 521 audio classes — sirens, alarms, glass, knocking | ✅ Bundled |
| **Face recognition** | Enrol people; app names them when they appear in frame | ✅ Bundled |
| **Scene description** | Describes what is in front of you | ✅ YOLO-based on Android |
| **Live captions** | Offline Whisper speech-to-text | ⚠️ Model pack needed |
| **Talk / AAC** | Quick-tap phrase bank, text-to-speech output | ✅ |
| **Emergency card** | Medical info + emergency contact, one-tap full-screen | ✅ |
| **Navigate** | Saved places, tracked items | ✅ |
| **4 languages** | UI + spoken output in EN / AR / FR / DE | ✅ |

---

## Speech in every language

The app speaks in the language you choose in **Settings → Speech → Voice language**:

| Setting | App speaks |
|---|---|
| Arabic (ar-SA) | سيارة أمامك · شخص على يسارك · إنذار حريق |
| French (fr-FR) | Voiture devant vous · Sirène à proximité |
| German (de-DE) | Auto vor Ihnen · Person links von Ihnen |
| English (en-US) | Car ahead · Person on your left |

UI language and speech language are independent — set them separately in Settings.

---

## Download

| Platform | File | Min version |
|---|---|---|
| **Android** (recommended) | [android.apk](https://github.com/Cambric-software/c-around/releases/latest/download/android.apk) | Android 8.0 (API 26), arm64 |
| Windows | [windows.zip](https://github.com/Cambric-software/c-around/releases/latest/download/windows.zip) | Windows 10/11, 64-bit |
| Linux | [linux.tar.gz](https://github.com/Cambric-software/c-around/releases/latest/download/linux.tar.gz) | glibc 2.31+, 64-bit |

**To install on Android:**
1. Download `android.apk` to your phone
2. Settings → Apps → Special app access → Install unknown apps → allow browser
3. Tap the downloaded file → Install

---

## Building from source

```bash
git clone https://github.com/Cambric-software/c-around.git
cd c-around/app
flutter pub get
flutter gen-l10n
flutter run                       # Android or desktop
flutter build apk --release       # Android APK
flutter test                      # 146 tests
flutter analyze                   # no issues
```

Requirements: Flutter stable, Dart ≥ 3.5, Java 17 (Android builds).

---

## Privacy

- No account, no sign-in, no cloud sync
- No analytics, no telemetry, no crash reporting to any server
- Camera frames analysed in memory and discarded — never recorded or transmitted
- Audio feeds only the on-device classifier — never transmitted
- Only optional network call: checking GitHub for a newer version (no personal data)

Full statement: [docs/PRIVACY.md](docs/PRIVACY.md)

---

## Repository layout

```
app/
  lib/
    app/            root widget, service wiring, app shell
    core/
      ai/           YOLO, YAMNet, face recognition, speech recognizer
      awareness/    camera loop, sound monitor, caption controller
      output/       TTS, announcer, speech strings (all 4 languages)
      settings/     settings service with all accessibility preferences
    features/
      screens/      Around, Talk, People, Navigate, Emergency, Settings
    l10n/           ARB files: app_en.arb, app_ar.arb, app_fr.arb, app_de.arb
  assets/models/    yolov8n.onnx, yamnet.onnx, det_500m.onnx, w600k_mbf.onnx
  assets/audio/     alarm.wav
  android/          Android project (minSdk 26, compileSdk 36)
docs/               GitHub Pages download site
.github/workflows/  CI, release pipeline, Pages deploy
```

---

## Licence

Proprietary. Source published for inspection only. See [LICENSE](LICENSE).  
Security: [SECURITY.md](SECURITY.md) — `security@cambric.dev`

© 2026 Cambric Software. All rights reserved.
