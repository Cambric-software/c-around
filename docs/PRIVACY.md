# Privacy

C Around has no account, no cloud and no telemetry. This document states exactly
what is stored and what leaves the device.

## Stored on the device

| Data | Location | Purpose |
|---|---|---|
| Preferences: needs, speech, contrast, text size, alert switches, medical card, emergency contact | `shared_preferences` | The person's chosen behaviour |
| Phrases | SQLite `phrases` | Quick communication |
| People: name, relationship, 512-float embedding, photo path | SQLite `people` + app support `people/` | Face recognition |
| Tracked items and last place | SQLite `items` | Finding things again |
| Saved places and coordinates | SQLite `places` | Straight-line navigation |
| Announcement history | SQLite `events` | Recent announcements |
| Caption history | SQLite `captions` | Reviewing what was said |
| Model packs | App support `model_packs/` | Offline inference |
| Installed versions | Versioned install root | In-place updates |

Nothing in this list is uploaded.

## What leaves the device

Only requests the person starts:

1. **Model pack download.** A direct HTTPS request to the URL shown in Settings
   (Hugging Face or the llama.cpp project). No identifier, account or usage data
   is attached.
2. **Update check.** A GET request to
   `https://api.github.com/repos/Cambric-software/c-around/releases/latest` when
   the person presses *Check for updates*. GitHub receives the request and may
   log the IP address as any web request does. C Around sends no device
   identifier, account or usage data.
3. **Opening a release or APK.** The system browser handles it.

There is no background check, no push channel, no analytics SDK, no crash
reporter and no advertising SDK.

## Erasing data

Settings → **Erase all local data** deletes:

- phrases, people and face embeddings, tracked items, saved places;
- announcement and caption history;
- the medical card and emergency contact;
- caption history held by the caption controller.

It does not delete downloaded model packs. Removing a person deletes their
embedding row and their photo file. Uninstalling removes the app and its local
data.

## Permissions

| Permission | Why |
|---|---|
| Camera | Scene awareness, text reading, face enrolment |
| Microphone | Sound alerts and captions |
| Location | Straight-line distance and compass direction to saved places |
| Vibrate | Haptic alerts |
| Wake lock | Keep a camera or microphone session alive while in use |
| Internet | Optional model downloads and the user-started update check |

Location is not stored with a place unless the person saves that place, and it
is never uploaded.

## Encryption

The SQLite database and enrolled photos are not encrypted at rest. They are
protected by the operating system's user account boundary. Use full-disk
encryption and a lock screen. C Around does not claim to protect data from
someone who has the unlocked device or its backups.

## Children

C Around does not collect personal data, so it does not knowingly collect data
from children. The medical card and emergency contact are optional fields the
person chooses to fill in.

## Changes

If a future version adds a network path or stores a new kind of data, this
document and the in-app About text must be updated in the same change.
