#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT_DIR/dist/LampControl.app"
DMG_PATH="$ROOT_DIR/dist/LampControl.dmg"
DMG_STAGE="$(mktemp -d "${TMPDIR:-/tmp}/lampcontrol-dmg-stage.XXXXXX")"

"$ROOT_DIR/scripts/build_app.sh"

rm -f "$DMG_PATH"
ditto --norsrc --noextattr --noacl "$APP_DIR" "$DMG_STAGE/LampControl.app"
ln -s /Applications "$DMG_STAGE/Applications"

hdiutil create \
  -volname "LampControl" \
  -srcfolder "$DMG_STAGE" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

rm -rf "$DMG_STAGE"

# Sign the DMG itself if a real identity is configured.
SIGN_ID="${SIGNING_IDENTITY:--}"
if [[ "$SIGN_ID" != "-" ]]; then
  codesign --force --sign "$SIGN_ID" "$DMG_PATH"
fi

echo "DMG généré: $DMG_PATH"
