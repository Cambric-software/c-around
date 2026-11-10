# Privacy Statement — C Around

**Last updated:** November 2026  
**Version:** 1.0.3

---

## Summary

C Around processes camera and microphone data entirely on your device. Nothing is recorded, stored long-term, or transmitted anywhere. There is no account, no login, no cloud backup, and no analytics.

---

## What the app collects and where it stays

| Data | Stored where | Sent anywhere |
|---|---|---|
| Camera frames (for object detection) | In memory only, discarded after each scan | ❌ Never |
| Microphone audio (for sound classification) | In memory only, discarded after each window | ❌ Never |
| Face embeddings (vectors, not photos) | SQLite on your device | ❌ Never |
| Phrases and AAC cards | SQLite on your device | ❌ Never |
| Medical card and emergency contact | SharedPreferences on your device | ❌ Never |
| Caption history | SQLite on your device | ❌ Never |
| Saved places and tracked items | SQLite on your device | ❌ Never |
| Settings and preferences | SharedPreferences on your device | ❌ Never |

---

## Network requests

The only outbound network request is an **optional update check** that reads:

```
GET https://api.github.com/repos/Cambric-software/c-around/releases/latest
```

This request:
- Carries no personal data beyond your IP address
- Is controlled by GitHub's privacy policy
- Can be disabled in **Settings → Security → Automatic update checks**
- Is never made without user consent

---

## Permissions

| Permission | Why needed |
|---|---|
| `CAMERA` | Object detection, face recognition, scene description |
| `RECORD_AUDIO` | Sound classification (YAMNet), live captions (Whisper) |
| `VIBRATE` | Haptic alerts for deaf/hard-of-hearing users |
| `WAKE_LOCK` | Keep screen on during awareness sessions |
| `ACCESS_FINE_LOCATION` | Navigate screen — saved places |
| `INTERNET` | Optional update check only |
| `FOREGROUND_SERVICE` | Keep awareness running when screen is off |

All permissions are requested at the point they are first needed. You can deny any permission and use the remaining features.

---

## Data deletion

All data is on your device. To delete it:
- **Individual items:** Use the delete button in each screen (People, Talk, Navigate)
- **Everything:** Uninstall the app

There is no server-side data to delete because nothing was ever sent.

---

## Children

C Around does not knowingly collect data from children. It has no account system and no data transmission, so it does not meet the threshold for COPPA or similar regulations.

---

## Contact

Questions: `security@cambric.dev`  
© 2026 Cambric Software
