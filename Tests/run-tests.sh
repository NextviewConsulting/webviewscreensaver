#!/bin/bash
# Builds the unit tests into an XCTest bundle with clang and runs them with xctest.
# Requires Xcode (the Command Line Tools alone do not ship XCTest).
#
#   ./Tests/run-tests.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/WebViewScreenSaver"
OUT="${TMPDIR:-/tmp}/wvss-tests"
BUNDLE="$OUT/WVSSTests.xctest"

SDK="$(xcrun --sdk macosx --show-sdk-path)"
FRAMEWORKS="$(xcrun --sdk macosx --show-sdk-platform-path)/Developer/Library/Frameworks"

rm -rf "$OUT"
mkdir -p "$BUNDLE/Contents/MacOS"
cp "$ROOT/Tests/Info.plist" "$BUNDLE/Contents/Info.plist"

# Only the model/networking sources are tested; the views need a running screensaver host.
clang -bundle -fobjc-arc -fmodules -Wall -Werror \
  -isysroot "$SDK" -mmacosx-version-min=14.0 \
  -include "$SRC/WebViewScreenSaver_Prefix.pch" -I "$SRC" \
  -F "$FRAMEWORKS" -framework XCTest -Xlinker -rpath -Xlinker "$FRAMEWORKS" \
  "$SRC/WVSSAddress.m" \
  "$SRC/WVSSAddressListFetcher.m" \
  "$SRC/WVSSConfig.m" \
  "$SRC/WVSSFileLogger.m" \
  "$ROOT"/Tests/*Tests.m \
  -o "$BUNDLE/Contents/MacOS/WVSSTests"

xcrun xctest "$BUNDLE"
