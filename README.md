# Liddy

**Turn the edges of your MacBook display into buttons.** Tap a corner to switch desktops, control your music, or quickly hide your screen during a meeting. No extra hardware needed.

Liddy listens to the motion sensor inside your MacBook. A tap twists the laptop slightly around its hinge, and the sensor captures that movement about 800 times per second. A small model trained on your taps then identifies which part of the display you touched.

Everything runs locally on your Mac. Liddy needs no network connection or account, and your data stays on your machine.

Made by **beast955**.

- [What a tap can do](#what-a-tap-can-do)
- [Getting good taps](#getting-good-taps)
- [Which Macs work](#which-macs-work)

## What a tap can do

Liddy divides your display into zones. Choose a 2×2, 2×3, or 3×3 layout, then assign an action to each zone.

| Action | What it does |
| --- | --- |
| **Desktop Left / Right** | Move to the previous or next desktop (Space). |
| **Play / Pause, Next, Previous** | Control the currently playing media, including Music, Spotify, and YouTube. |
| **New Note** | Open a new note in Notes. |
| **Open App** | Launch an app or bring it to the front if it is already running. |
| **Privacy Shield** | Mute your microphones, turn off your meeting camera (Zoom, Teams, Webex, or Google Meet), and hide your screen. Tap again or click to return; your microphone is restored to its previous state. |

The default 2×2 layout assigns **Desktop Left** to the top-left zone, **Desktop Right** to the top-right, **Play / Pause** to the bottom-left, and **Privacy Shield** to the bottom-right.

Liddy is designed to ignore everyday movement, including typing, clicking, scrolling, moving the pointer or lid, and knocks on the desk.

## Getting good taps

- Give each zone's corner dot a quick, light fingertip flick. Don't press hard: force isn't needed, and pressing on a display can leave marks.
- Let the screen settle between taps. About half a second is usually enough.
- During calibration, the meter shows **Good tap**, **A little crisper**, or **Gentler is fine**. Aim for green.
- If taps are often misread, open **Settings → Training** to check reliability by zone. **Calibrate Again** adds taps where they are needed. Adjust minimum tap strength in **Settings → Detection**.

With crisp taps on a 2×2 grid, Liddy read 90% of taps correctly in our testing. When Liddy isn't confident, it ignores the tap instead of guessing.

## Which Macs work

- Apple Silicon MacBook Air or Pro with M2 or later, provided it has a motion sensor.
- 14-inch or 16-inch MacBook Pro with M1 Pro or M1 Max.
- macOS 14 Sonoma or later.

The M1 MacBook Air, 13-inch M1 MacBook Pro, desktop Macs, and Intel Macs are not supported because they do not have the required motion sensor.

Liddy relies on a sensor that Apple does not document. A future macOS update could change how the sensor works or make it unavailable.

## Native macOS app

The native menu bar app and its signed DMG release workflow are in [LiddyApp](LiddyApp/README.md). After the Apple signing secrets are configured, each pushed version tag produces a DMG in [GitHub Releases](https://github.com/beast955/liddy/releases).
