#!/bin/sh
# Builds Liddy.app and installs it to ~/Applications.
#   scripts/build.sh            release build + install
#   scripts/build.sh --no-install
set -e
MODE="${1:---install}"
SIGN_IDENTITY="${LIDDY_SIGN_IDENTITY:--}"
VERSION="${LIDDY_VERSION:-1.0}"
BUILD_NUMBER="${LIDDY_BUILD_NUMBER:-1}"
cd "$(dirname "$0")/.."
ROOT="$(pwd)"
BUILD="$ROOT/build"
APP="$BUILD/Liddy.app"
SDK="$(xcrun --show-sdk-path)"

# Command Line Tools 26.1 on this Mac ships a stray usr/include/swift/module.modulemap that redefines
# SwiftBridging and breaks every Foundation import. Hide it with a VFS overlay (no system files touched).
FIX="$ROOT/scripts/toolchain-fix"
mkdir -p "$FIX"
: > "$FIX/empty.modulemap"
cat > "$FIX/overlay.yaml" <<EOF
{ "version": 0, "case-sensitive": "false", "roots": [ { "type": "file",
  "name": "/Library/Developer/CommandLineTools/usr/include/swift/module.modulemap",
  "external-contents": "$FIX/empty.modulemap" } ] }
EOF
swiftc_() { swiftc -sdk "$SDK" -target arm64-apple-macos14.0 -vfsoverlay "$FIX/overlay.yaml" "$@"; }

mkdir -p "$BUILD"
echo "Compiling…"
set --
for f in $(cd Sources && find . -name '*.swift'); do set -- "$@" "Sources/$f"; done
swiftc_ -O -swift-version 5 -parse-as-library \
  -framework IOKit -framework CoreAudio -framework CoreMediaIO -framework ServiceManagement \
  "$@" -o "$BUILD/Liddy"

echo "Bundling…"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BUILD/Liddy" "$APP/Contents/MacOS/Liddy"
cp Resources/Info.plist "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$APP/Contents/Info.plist"
if [ ! -f "$BUILD/AppIcon.icns" ] || [ scripts/make_icon.swift -nt "$BUILD/AppIcon.icns" ]; then
  swiftc_ -O scripts/make_icon.swift -o "$BUILD/make_icon"
  rm -rf "$BUILD/AppIcon.iconset"
  "$BUILD/make_icon" "$BUILD/AppIcon.iconset"
  iconutil -c icns "$BUILD/AppIcon.iconset" -o "$BUILD/AppIcon.icns"
fi
cp "$BUILD/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
if [ "$SIGN_IDENTITY" = "-" ]; then
  codesign --force --sign - --identifier dev.liddy.Liddy "$APP"
else
  codesign --force --sign "$SIGN_IDENTITY" --identifier dev.liddy.Liddy \
    --options runtime --timestamp --entitlements Resources/Liddy.entitlements "$APP"
fi
codesign --verify --deep --strict --verbose=2 "$APP"

if [ "$MODE" != "--no-install" ]; then
  DEST="$HOME/Applications/Liddy.app"
  mkdir -p "$HOME/Applications"
  pkill -x Liddy 2>/dev/null && sleep 0.5 || true
  rm -rf "$DEST"
  cp -R "$APP" "$DEST"
  echo "Installed to $DEST"
fi
echo "Done."
