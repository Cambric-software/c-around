# Accessibility

C Around is built for five overlapping groups: blind, low-vision, deaf,
hard-of-hearing and non-verbal people. A person can select more than one need,
and every default can be overridden.

## Needs and defaults

| Need | What changes |
|---|---|
| Blind | Speech on, haptics on, larger text, screen-reader announcements |
| Low vision | High contrast, larger text, stronger borders |
| Deaf | Flash on, haptics on, audible emergency tone off |
| Hard of hearing | Captions on, visual alerts |
| Non-verbal | Phrases and cards ready, text-to-speech available |

The needs page says explicitly that this is not a diagnosis and that nothing is
permanent.

## Output rules

Every observation goes through `Announcer`, which decides what is spoken, felt,
flashed and stored. That is why the cooldown and the "do not repeat the same
sentence" rule apply on every screen.

- **Speech** can be turned off. Warnings and danger still reach the screen,
  vibration and flash.
- **Vibration** uses a different pattern for warning and danger.
- **Flash** is a short colour pulse, not a strobe. It is intended for deaf and
  hard-of-hearing users and can be turned off.
- **Screen reader** users get the same sentence as a live-region announcement
  through the platform semantics service, so TalkBack or Narrator is not
  dependent on the app's own voice.
- **Captions** are shown in large text with the same contrast rules as the rest
  of the app and are stored locally for review.

## Visual design

- The page is near-black or near-white, never mid-grey.
- The primary teal clears 4.5:1 on both light and dark surfaces.
- Amber is only used for a warning that is also carried by an icon and a word,
  so colour is never the only signal.
- High contrast is a separate palette, not an opacity switch.
- Text scale goes from 90% to 200%.
- Touch targets are at least 44–56 px high.
- The camera preview is optional; every action also works from a chosen photo.

## Emergency

A red **SOS** button is in every app bar. It opens the emergency screen, which
has a loud alarm, a medical card, the emergency contact and a call action. The
emergency screen does not show a second SOS button.

## Microphone and camera

One `MicrophoneSource` is shared by sound alerts and captions through reference
counting, so the app does not fight the operating system for the microphone.
The camera uses still capture on a timer rather than a continuous stream, which
keeps it working across desktop and mobile backends and makes each scan a
bounded unit of work.

## Language

The interface is English in 1.0. Speech output can use another installed system
voice, and the caption model is multilingual, but the UI strings are English.
The app does not claim a translated interface.

## Testing accessibility changes

1. Run with a screen reader on each platform.
2. Turn speech off and confirm warnings still appear as text, flash and haptics.
3. Set text scale to 200% and check that no button or label is clipped.
4. Turn on high contrast in both light and dark mode.
5. Trigger a danger alert and confirm it is not conveyed by colour alone.
6. Open Emergency from every tab.
