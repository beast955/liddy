#!/bin/bash
# Builds and runs the Liddy test suites.
#   scripts/test.sh                              ml detector logic ui (no side effects)
#   scripts/test.sh hardware actions guard e2e   real-system suites (switch Spaces, mute the mic, open apps…)
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$(pwd)"
FIX="$ROOT/scripts/toolchain-fix"
[ -f "$FIX/overlay.yaml" ] || { echo "Run scripts/build.sh once first (it creates the toolchain overlay)"; exit 1; }

files=()
while IFS= read -r -d '' f; do files+=("$f"); done < <(find Sources Tests -name '*.swift' ! -name 'LiddyApp.swift' -print0)

mkdir -p build
echo "Compiling tests (${#files[@]} files)…"
swiftc -O -swift-version 5 -sdk "$(xcrun --show-sdk-path)" -target arm64-apple-macos14.0 -vfsoverlay "$FIX/overlay.yaml" \
  -framework IOKit -framework CoreAudio -framework CoreMediaIO -framework ServiceManagement -framework AVFoundation \
  "${files[@]}" -o build/LiddyTests
exec build/LiddyTests "$@"
