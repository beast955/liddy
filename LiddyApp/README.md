# Liddy for macOS

A menu bar app that turns gentle taps on your MacBook display into actions, using only the built-in
motion sensor. No touch hardware, camera or mirror.

## Build, install, and ship

For local development, run `scripts/build.sh`. It builds `build/Liddy.app`, signs ad hoc, and installs to
`~/Applications/Liddy.app`. Pass `--no-install` to skip installation.

For a production DMG, use a full Xcode installation and an Apple Developer ID Application certificate. Store notarization credentials in the keychain with `xcrun notarytool store-credentials`, then set:

```bash
export LIDDY_SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)"
export LIDDY_NOTARY_PROFILE="liddy-notary"
export LIDDY_VERSION="1.0.0"
export LIDDY_BUILD_NUMBER="1"
scripts/package_dmg.sh
```

The release script signs with the hardened runtime, notarizes and staples the app and disk image, then verifies the resulting `build/distribution/Liddy-<version>.dmg`. It also writes a SHA-256 checksum. Keep Apple credentials in Keychain; do not put passwords or certificate private keys in the project.

## GitHub releases

The GitHub Actions workflow builds and publishes a signed, notarized DMG whenever a version tag such as `v1.0.0` is pushed. Configure these encrypted repository secrets first:

- `LIDDY_DEVELOPER_ID_P12_BASE64`: base64 contents of the exported Developer ID Application certificate.
- `LIDDY_DEVELOPER_ID_P12_PASSWORD`: the certificate export password.
- `LIDDY_SIGN_IDENTITY`: exact identity label, for example `Developer ID Application: Name (TEAMID)`.
- `LIDDY_NOTARY_APPLE_ID`, `LIDDY_NOTARY_TEAM_ID`, and `LIDDY_NOTARY_PASSWORD`: Apple ID, team ID, and app-specific password for notarization.

Add them under **Settings → Secrets and variables → Actions** in the GitHub repository. Export the Developer ID certificate from Keychain as a password-protected P12 file, then store its base64 text as the certificate secret (on macOS: `base64 -i DeveloperID.p12 | tr -d '\n'`). Then push a version tag such as `v1.0.0`. The workflow attaches the DMG and its SHA-256 checksum to the GitHub Release. It uses an ephemeral keychain on the hosted macOS runner.

## Zone actions

Desktop Left / Right · New Note · Play/Pause · Next / Previous Track · Open App (launch or bring to front) ·
Privacy Shield.

**Privacy Shield** blurs every screen instantly, mutes every microphone at the system level (restored
exactly afterwards), and if a camera is in use, turns it off in Zoom, Microsoft Teams, Webex or
Google Meet (Chrome, Edge, Brave, Safari), then checks it actually stopped. Tap the zone again or click
anywhere to undo it all, including turning the camera back on.

## Permissions

- **Accessibility**: required for desktop switching, media keys, New Note and meeting camera control.
- **Input Monitoring**: some Macs need it before the motion sensor streams.
- **Automation**: asked the first time Privacy Shield looks for a Google Meet tab.

The local development build is ad-hoc signed. A production Developer ID build keeps a stable signature for macOS privacy permissions.

## Layout

| Path | Role |
|---|---|
| `Sources/Liddy/Core/IMUReader.swift` | IOKit access to the IMU (~800 Hz) and lid-angle sensor |
| `Sources/Liddy/Core/TapDetector.swift` | High-pass, adaptive gyro trigger, 200 ms tap windows, input/lid gates |
| `Sources/Liddy/Core/Features.swift` | 70 tap features, identical to the Python prototype |
| `Sources/Liddy/Core/Classifiers.swift`, `ZoneModel.swift` | Logistic regression, kNN, nearest centroid; cross-validation; open-set rejection |
| `Sources/Liddy/Core/Store.swift` | Config and dataset in `~/Library/Application Support/Liddy` |
| `Sources/Liddy/Actions/` | Zone actions, key/media events, Privacy Shield, meeting camera control |
| `Sources/Liddy/UI/` | Menu bar panel, Settings, full-screen calibration, on-screen tap feedback |
| `Sources/Liddy/App/` | App entry, central model |
