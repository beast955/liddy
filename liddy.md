# Liddy: tap zones on your MacBook display

**Use gentle taps on your MacBook display as shortcuts, with no extra hardware.** Liddy divides the screen into zones and recognizes which zone you tapped by reading the motion sensor (IMU) already inside the laptop. It uses no touchscreen, camera, mirror, or add-on.

Liddy does not track fingers, support dragging, or detect a held press. It answers one question for each tap: **which zone was tapped?**

---

## First results

The following measurements were collected in one session on an M3 MacBook Air 13-inch (Mac15,12) running macOS 27.0.1. The lid was at 130–131°, and the test used fingertip taps on a 2×2 grid, with 15 taps per zone (60 taps total).

| Layout | Best model | Cross-validated accuracy |
|---|---|---|
| 2×2 (four zones) | SVM | **95%** |
| Top / bottom | SVM | **100%** |
| Left / right | SVM, logistic regression | **95%** |

- Fingertip taps produced **3.7–13 °/s** of gyroscope twist, compared with idle noise of about **0.1–0.2 °/s**.
- All three errors were left/right mix-ups within the same row: zone 2 was read as zone 1 twice, and zone 4 as zone 3 once. Top and bottom were never confused.
- Accuracy by training examples per zone was 82% at 2 taps, 89% at 5 taps, and 94% at 10 taps.

These are results from a single session, lid angle, and surface. Accuracy may fall when the lid angle or surface changes, until those conditions are included in calibration. The 3×3 layout has not yet been measured.

## How it works

### The motion behind a tap

A tap on the display sends a small movement through the hinge and twists the laptop. A Bosch six-axis IMU on the logic board, in the base, measures the movement with its gyroscope at about 800 Hz.

- Tap location changes the twist. Taps on different sides can twist the laptop in opposite directions; distance from the hinge changes the balance between twist and shake.
- A desk bump tends to move the laptop sideways rather than twist it. Liddy therefore uses the gyroscope as its tap trigger, rather than the accelerometer.

Liddy learns a fingerprint for each zone from recorded examples. It matches new taps to those examples instead of calculating a precise touch position.

### Detection pipeline

```text
IMU (accelerometer + gyroscope, ~794 Hz each)
  → 5 Hz high-pass filter
  → adaptive trigger on gyroscope twist
  → wait 170 ms
  → capture a 200 ms window (30 ms before, 170 ms after the trigger)
  → ignore if recent typing/clicking/scrolling or lid movement is detected
  → extract 70 features
  → classify and check whether the tap is familiar
  → show the zone and confidence
```

1. **Read the sensors.** Liddy uses undocumented IOKit HID services (`AppleSPUHIDDevice`, usage page `0xFF00`, usages 3 and 9). This requires Input Monitoring permission, not root access. Lid angle, reported in whole degrees, is sampled at 20 Hz to provide context and suppress detections while the lid moves.
2. **Detect taps.** The trigger fires when high-passed twist magnitude exceeds the greater of a minimum floor and sensitivity multiplied by estimated idle noise. The noise estimate updates only while the laptop is idle. A brief cooldown prevents one tap from triggering twice.
3. **Filter out everyday input.** A tap is ignored if a key, click, or scroll was detected in the previous 0.3 seconds. Liddy uses `CGEventSourceSecondsSinceLastEventType`, which needs no additional permission. Taps are also ignored if the lid angle changed by at least 2°.
4. **Describe the tap.** Features are scaled by tap strength so that gentle and firm taps from the same zone can still match. They include:
   - Twist direction at its peak and net early rotation on each axis
   - The split between twist and shake across the three axes
   - Twist relative to shake, and overall tap strength
   - How quickly movement fades and four frequency bands
   - An 80 ms waveform template, weighted so it does not overwhelm the hand-crafted features
5. **Choose a zone.** Five models are cross-validated during training: k-nearest neighbours, nearest centroid, SVM, logistic regression, and random forest. Liddy selects the best automatically, or you can choose a model yourself.
6. **Reject unfamiliar taps.** If a tap is much farther from its predicted zone's examples than that zone's usual taps (2× by default), Liddy rejects it. Taps that match recorded noise examples are rejected too.

## The interface

Run `./start.sh` to start the interface at `http://127.0.0.1:8765`.

| Tab | Purpose | What you can see or do |
|---|---|---|
| **1 · Monitor** | Check taps and tune detection | Live gyroscope, twist, and accelerometer traces; trigger line; colored tap markers; waveform and tap details; event log. |
| **2 · Calibrate** | Record examples for each zone | Choose a grid, start calibration, and tap the highlighted zones. Zones appear in shuffled groups. Record 30 seconds of desk knocks and lid movements as noise examples. Undo, delete, or clear examples. |
| **3 · Model** | Compare layouts and classifiers | Accuracy by model on the full grid and merged layouts, confusion matrix, learning curve, 2D feature map, and average gyroscope twist per zone. |
| **4 · Live** | Use zone predictions | Full-screen grid highlights predictions and confidence; rejected and ignored taps are also shown. Optionally run a shell command for each zone. |

Status indicators in the upper right show the IMU rate, lid angle, idle noise, active trigger, mode, and active model with its accuracy.

### Zone actions

Each zone can run a shell command, with `{zone}` replaced by that zone's number. Actions are off by default.

```sh
say {zone}
open -a "Mission Control"
open -g "hammerspoon://zone?n={zone}"
open -g "btt://trigger_named/?trigger_name=zone{zone}"
```

## Install and run

Liddy needs an Apple Silicon MacBook with the required IMU: M2 or later, or M1 Pro / M1 Max. The M1 MacBook Air and 13-inch M1 MacBook Pro do not have one.

```sh
./start.sh
```

On first launch, the script creates a Python virtual environment and installs NumPy and scikit-learn using `uv`. It then starts the local server and opens the interface in a browser. Stop it with **Ctrl+C**.

If the interface reports that no IMU data is arriving, allow Input Monitoring for the terminal app in **System Settings → Privacy & Security → Input Monitoring**, then restart Liddy.


### Suggested first session

1. **Monitor:** Gently tap each corner. Each tap should cross the dashed trigger line once and create a marker. Typing should be shown as ignored input.
2. **Calibrate:** Begin with a 2×2 grid and 15 taps per zone, then record 30 seconds of noise examples.
3. **Model:** If the 2×2 results reach 90% accuracy or better, try a 3×3 grid with 15–20 taps per zone. Keep the layout that works reliably for you.
4. **Live:** Enable zone actions after predictions look right.

**Use light taps.** Pressing hard on a laptop display can leave pressure marks, and this kind of damage is usually not covered by warranty. A light fingertip-pad flick is recommended; a gentle knuckle tap near the top or side edges can be an alternative.

## Settings

Settings are saved in `data/config.json` and can also be changed in the interface.

| Setting | Default | Description |
|---|---:|---|
| Sensitivity (`k`) | 6 | Multiplier applied to idle twist noise when setting the trigger. |
| Trigger floor (`min_thresh`) | 1.0 °/s | Minimum trigger strength. |
| Cooldown (`refractory`) | 0.35 s | Minimum time between detected taps. |
| Input gate (`gate_s`) | 0.3 s | Ignore taps this soon after typing, clicking, or scrolling. |
| Gating (`gating`) | On | Enable or disable typing, click, scroll, and lid-movement filters. |
| Reject factor (`reject_factor`) | 2.0 | How far a tap can differ from its predicted zone before being rejected. |
| Model (`model_kind`) | `auto` | Choose `auto`, `knn`, `centroid`, `svm`, `logreg`, or `rf`. |
| Zone actions | Off | Run configured shell commands for zones. |

## Recorded data

`data/dataset.json` stores the grid and labeled tap examples, including the zone or `noise` label, time, lid angle, peak values, and raw 200 ms high-passed gyroscope and accelerometer windows (160 × 3 values each at 800 Hz).

Features are recalculated from the raw windows when the data is loaded, so feature improvements also apply to existing recordings. Changing the grid removes zone tap examples but retains noise examples. |

### Local server security

The server listens on `127.0.0.1` only. Since zone actions can run shell commands, Liddy generates a random token at each launch and embeds it in the interface. It also refuses requests with a non-local Host header. These checks prevent other websites from changing settings or triggering commands.

## Limitations

- **Zones, not touch tracking:** Liddy recognizes taps only. It does not track a finger, drag, or detect a press and hold.
- **Calibration depends on conditions:** A model trained at one lid angle or on a desk may be less reliable on your lap or at another angle until those conditions are included in calibration.
- **Undocumented sensor interface:** Apple does not document the IMU interface. A macOS update could change it. It has worked from macOS 13 through 27.0.1.
- **Lid-angle readings:** The sensor reports whole degrees and is unreliable on some M1 models.
- **Prototype performance:** The Python prototype uses about 3–5% of one CPU core while streaming. A tap-to-result takes roughly 170 ms, mostly to collect the full tap window.

## Roadmap

1. **Improve reliability:** Add calibration profiles for lid angle and desk-versus-lap use, a quick re-anchoring flow, and longer false-trigger tests during typing and desk use.
2. **Explore microphone confirmation:** Test whether the built-in microphone, with Apple's voice processing disabled, can provide a second signal and help resolve left/right confusion.
3. **Build a native app:** Move to a Swift menu-bar app with a background helper, vDSP features, and Core ML or Swift k-nearest neighbours. Target under 170 ms latency and about 3% CPU usage.
4. **Optional research:** Explore webcam hand pose as a hint for tap location and ultrasonic sweeps from speakers to the microphone.

## Background and references

Research notes are in `reports/MacBook lid tap zone detection.md` and `research_notes/`. Related work includes:

- **[Apple Silicon accelerometer notes](https://github.com/olvvier/apple-silicon-accelerometer):** Documentation of the IMU report format.
- **TapPrints (MobiSys 2012):** Used a phone's built-in accelerometer and gyroscope to locate screen taps, with accuracy up to about 90%.
- **Knocker (IMWUT 2019):** Identified objects from knocks with roughly 20 training knocks per object.
- **Location template matching (Ing et al.):** Matched taps to recorded examples instead of calculating a position.
