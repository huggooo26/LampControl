#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/.build/release"
APP_DIR="$ROOT_DIR/dist/LampControl.app"
INFO_PLIST_SRC="$ROOT_DIR/Info.plist"
INFO_PLIST_DST="$APP_DIR/Contents/Info.plist"

# Resolve marketing version from VERSION env var, or git tag, or fall back to Info.plist value.
if [[ -n "${VERSION:-}" ]]; then
  MARKETING_VERSION="${VERSION#v}"
elif git -C "$ROOT_DIR" describe --tags --abbrev=0 >/dev/null 2>&1; then
  MARKETING_VERSION="$(git -C "$ROOT_DIR" describe --tags --abbrev=0 | sed 's/^v//')"
else
  MARKETING_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$INFO_PLIST_SRC")"
fi

# Build number = number of commits if not explicitly provided.
if [[ -n "${BUILD_NUMBER:-}" ]]; then
  BUILD_NUMBER_VALUE="$BUILD_NUMBER"
elif git -C "$ROOT_DIR" rev-parse HEAD >/dev/null 2>&1; then
  BUILD_NUMBER_VALUE="$(git -C "$ROOT_DIR" rev-list --count HEAD)"
else
  BUILD_NUMBER_VALUE="1"
fi

cd "$ROOT_DIR"
swift build -c release

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Frameworks"

cp "$BUILD_DIR/LampControl" "$APP_DIR/Contents/MacOS/LampControl"
cp "$INFO_PLIST_SRC" "$INFO_PLIST_DST"

# Inject the resolved versions into the bundled Info.plist.
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $MARKETING_VERSION" "$INFO_PLIST_DST"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER_VALUE" "$INFO_PLIST_DST"

# Bundle Sparkle.framework if it was built as part of SwiftPM.
SPARKLE_FRAMEWORK_SRC="$BUILD_DIR/Sparkle.framework"
if [[ -d "$SPARKLE_FRAMEWORK_SRC" ]]; then
  cp -R "$SPARKLE_FRAMEWORK_SRC" "$APP_DIR/Contents/Frameworks/Sparkle.framework"
elif [[ -d "$BUILD_DIR/PackageFrameworks/Sparkle.framework" ]]; then
  cp -R "$BUILD_DIR/PackageFrameworks/Sparkle.framework" "$APP_DIR/Contents/Frameworks/Sparkle.framework"
else
  echo "Avertissement: Sparkle.framework introuvable dans $BUILD_DIR — vérifie que swift build l'a généré."
fi

# Codesign: if SIGNING_IDENTITY is provided (e.g. Developer ID Application: Hugo Informatique),
# perform a hardened-runtime, deep-signed bundle. Otherwise fall back to ad-hoc signing so the
# bundle at least passes Sparkle's own signature checks.
SIGN_ID="${SIGNING_IDENTITY:--}"
ENTITLEMENTS_ARG=()
if [[ -f "$ROOT_DIR/scripts/LampControl.entitlements" ]]; then
  ENTITLEMENTS_ARG=(--entitlements "$ROOT_DIR/scripts/LampControl.entitlements")
fi

if [[ -d "$APP_DIR/Contents/Frameworks/Sparkle.framework" ]]; then
  codesign --force --deep --options runtime --timestamp --sign "$SIGN_ID" "$APP_DIR/Contents/Frameworks/Sparkle.framework" || true
fi

# Use ${array[@]+"${array[@]}"} so an empty ENTITLEMENTS_ARG doesn't trip
# `set -u` (bash treats `"${empty[@]}"` as referencing an unset variable).
codesign --force --deep --options runtime --timestamp \
  ${ENTITLEMENTS_ARG[@]+"${ENTITLEMENTS_ARG[@]}"} \
  --sign "$SIGN_ID" "$APP_DIR" || codesign --force --deep --sign - "$APP_DIR"

echo "App générée: $APP_DIR (version $MARKETING_VERSION build $BUILD_NUMBER_VALUE, signée: $SIGN_ID)"
