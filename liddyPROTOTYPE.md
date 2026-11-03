# Liddy prototype (Python)

Recognize taps on zones of a MacBook display using the laptop's built-in motion sensor. A tap twists the machine slightly around its hinge; the gyroscope in the base detects that movement at about 800 Hz. A classifier trained on your Mac's tap examples learns which zone produced it.

## Run

```sh
./start.sh
```

On first run, this creates `.venv`, starts the local server at `http://127.0.0.1:8765`, and opens the interface in your browser.

Liddy needs an Apple Silicon MacBook with the required IMU: M2 or later, or M1 Pro / M1 Max. If no sensor data arrives, allow Input Monitoring for the app that launched Liddy in **System Settings → Privacy & Security → Input Monitoring**, then restart it.

## Workflow

1. **Monitor:** Watch the live gyroscope and accelerometer traces. Tap gently and confirm that taps cross the dashed trigger line while typing and desk knocks are ignored. Adjust sensitivity and the trigger floor if needed.
2. **Calibrate:** Choose a grid (start with 2×2), press **Start**, and tap the highlighted zone. Use **Full screen** so the zones line up with the places you tap on the display. Add 30 seconds of noise examples, such as desk knocks and lid movement. The model retrains when calibration finishes.
3. **Model:** Review cross-validated accuracy for five classifiers and merged layouts (columns, rows, left/right, and corners), along with the confusion matrix, learning curve, feature map, and per-zone gyroscope signatures. Choose the finest layout that remains reliable.
4. **Live:** The grid lights up for each prediction. You can optionally map zones to shell commands, such as `say {zone}`, `open -a "Mission Control"`, or Hammerspoon and BetterTouchTool URLs.

Use a light fingertip-pad tap. Pressing hard on the display can leave pressure marks.
