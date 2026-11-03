#!/bin/bash
# Build, sign, notarize, and package a production Liddy DMG.
# Configure LIDDY_SIGN_IDENTITY and LIDDY_NOTARY_PROFILE before running.
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"
BUILD="$ROOT/build"
DIST="$BUILD/distribution"
IDENTITY="${LIDDY_SIGN_IDENTITY:-}"
PROFILE="${LIDDY_NOTARY_PROFILE:-}"
VERSION="${LIDDY_VERSION:-1.0}"
BUILD_NUMBER="${LIDDY_BUILD_NUMBER:-1}"

if [ -z "$IDENTITY" ]; then
  echo "Set LIDDY_SIGN_IDENTITY to the exact Developer ID Application certificate name." >&2
  exit 2
fi
if [ -z "$PROFILE" ]; then
  echo "Set LIDDY_NOTARY_PROFILE to a notarytool keychain profile name." >&2
  exit 2
fi
if ! xcodebuild -version >/dev/null 2>&1; then
  echo "A full Xcode installation is required to build the SwiftUI app. Select Xcode with xcode-select." >&2
  exit 2
fi
if ! security find-identity -v -p codesigning | grep -Fq "$IDENTITY"; then
  echo "The requested Developer ID signing identity is not available in the keychain." >&2
  exit 2
fi

mkdir -p "$DIST"
LIDDY_SIGN_IDENTITY="$IDENTITY" LIDDY_VERSION="$VERSION" LIDDY_BUILD_NUMBER="$BUILD_NUMBER" \
  ./scripts/build.sh --no-install
APP="$BUILD/Liddy.app"
ZIP="$DIST/Liddy-$VERSION-notary.zip"
DMG="$DIST/Liddy-$VERSION.dmg"
STAGE="$DIST/stage"

codesign --verify --deep --strict --verbose=2 "$APP"
rm -f "$ZIP" "$DMG"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP"
notarize() {
  if [ -n "${LIDDY_NOTARY_KEYCHAIN:-}" ]; then
    xcrun notarytool submit "$1" --keychain-profile "$PROFILE" --keychain "$LIDDY_NOTARY_KEYCHAIN" --wait
  else
    xcrun notarytool submit "$1" --keychain-profile "$PROFILE" --wait
  fi
}
notarize "$ZIP"
xcrun stapler staple "$APP"
xcrun stapler validate "$APP"

rm -rf "$STAGE"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/Liddy.app"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "Liddy $VERSION" -srcfolder "$STAGE" -ov -format UDZO "$DMG"
codesign --force --sign "$IDENTITY" --timestamp "$DMG"
notarize "$DMG"
xcrun stapler staple "$DMG"
xcrun stapler validate "$DMG"
hdiutil verify "$DMG"
spctl --assess --type open --context context:primary-signature --verbose=4 "$DMG"
shasum -a 256 "$DMG" > "$DMG.sha256"

echo "Production DMG: $DMG"
echo "SHA-256: $(cut -d ' ' -f 1 "$DMG.sha256")"
