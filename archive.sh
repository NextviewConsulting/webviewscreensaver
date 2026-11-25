#!/bin/bash

set -eu

PRJ_DIR="WebViewScreenSaver"
BUILD_DIR="build"
PKG_DIR="WebViewScreenSaver.saver"
if [ -z "${VERSION:-}" ]; then
  ARTIFACT="WebViewScreenSaver.saver.zip"
else
  ARTIFACT="WebViewScreenSaver-${VERSION}.zip"
fi

pushd "$PRJ_DIR"
xcodebuild -project WebViewScreenSaver.xcodeproj -scheme WebViewScreenSaver -configuration Release clean archive -archivePath "$BUILD_DIR/build.xcarchive" CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO
# Ad-hoc signed by default. Once an Apple Developer ID is available, set SIGN_IDENTITY
# (e.g. "Developer ID Application: Nextview Consulting (TEAMID)") to sign with the
# hardened runtime and a secure timestamp, which notarization requires.
SIGN_IDENTITY="${SIGN_IDENTITY:--}"
if [ "$SIGN_IDENTITY" = "-" ]; then
  codesign --sign - --force "$(find "$BUILD_DIR" -iname "*.saver")"
else
  codesign --sign "$SIGN_IDENTITY" --force --options runtime --timestamp "$(find "$BUILD_DIR" -iname "*.saver")"
fi

ln -s "$(find "$BUILD_DIR" -iname "*.saver")" "$PKG_DIR"
rm -f "../$ARTIFACT"
zip -r "../$ARTIFACT" "$PKG_DIR"

rm "$PKG_DIR"
rm -rf "$BUILD_DIR"

popd

