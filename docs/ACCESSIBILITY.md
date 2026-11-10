# Accessibility — C Around v1.0.3

C Around is built specifically for blind, deaf, hard-of-hearing and non-verbal users. This document describes how every output channel works.

---

## First launch — choose your needs

The welcome screen asks you to select your accessibility needs. C Around adjusts its defaults automatically:

| Need | Default changes |
|---|---|
| **Blind** | Speech on, haptics on, text scale increased |
| **Low vision** | High contrast on, text scale increased |
| **Deaf** | Screen flash on, haptics on, audio alerts off |
| **Hard of hearing** | Screen flash on, haptics on |
| **Non-verbal** | Speech on (for AAC output) |

You can change every setting individually in Settings at any time.

---

## Output channels

### 1. Spoken output (TTS)
- Uses the Android/Windows/Linux platform TTS engine
- Language: set in **Settings → Speech → Voice language** — Arabic, French, German, English
- Rate and pitch: adjustable in Settings
- All spoken messages are translated — the app never reads English words when Arabic is selected

### 2. Vibration
- Danger alerts: long triple pulse
- Warning alerts: short double pulse
- Controlled by **Settings → Accessibility → Vibration alerts**

### 3. Screen flash
- Full-screen colour pulse for every alert
- For users who cannot hear sound
- Controlled by **Settings → Accessibility → Screen flash alerts**

### 4. Semantic accessibility
- Every screen announces its content to screen readers (TalkBack on Android)
- All interactive elements have accessible labels
- Text sizes respect system font scale and the in-app text scale setting

---

## What gets spoken and when

### Continuous camera awareness (Around screen)

| Event | Spoken (English) | Level |
|---|---|---|
| Car/truck/bus ahead | "Car ahead." | Danger |
| Person very close | "Person very close, on your left." | Warning |
| Person detected | "Person ahead." | Info |
| Dog detected | "Dog on your right." | Warning |
| Sharp object | "Sharp object ahead." | Warning |
| Obstacle | "Obstacle ahead." | Warning |
| Enrolled face | "Sara is on your left." | Info |

### Sound monitor

| Sound | Spoken | Level |
|---|---|---|
| Fire/smoke alarm | "Fire alarm detected." | Danger |
| Siren | "Siren nearby." | Danger |
| Breaking glass | "Glass breaking." | Danger |
| Car horn | "Car horn nearby." | Warning |
| Dog barking | "Dog barking nearby." | Warning |
| Shouting | "Someone shouting nearby." | Warning |
| Doorbell | "Doorbell." | Info |
| Knocking | "Knocking." | Info |

All messages above are translated when you select Arabic, French, or German.

### Announcement cooldown

Repeated identical announcements are suppressed for 6 seconds (adjustable in Settings → Accessibility → Announcement cooldown). Danger alerts use half the cooldown.

---

## Emergency card

The emergency card shows:
- Your name, blood type, medical conditions, allergies, medications
- Emergency contact name and phone number

It can be opened with one tap from the Emergency tab. No unlock required.

Set it up in **Settings → Medical card**.

---

## AAC / Talk

The Talk screen provides:
- **Quick cards** — most-used phrases tapped to speak instantly
- **All phrases** — full phrase bank organised by category
- **Free text** — type anything, tap Speak
- Phrases: "I need help", "I need water", "I am in pain", "Please call my family" (10 seeded, unlimited user-added)

---

## Supported languages

| Language | UI | Spoken output |
|---|---|---|
| English | ✅ | ✅ |
| Arabic (RTL) | ✅ | ✅ |
| French | ✅ | ✅ |
| German | ✅ | ✅ |
