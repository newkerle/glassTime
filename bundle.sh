#!/bin/bash
# Builds GlassTime and packages the binary into a proper, double-clickable
# GlassTime.app bundle (Info.plist + app icon + ad-hoc code signature).
#
#   ./bundle.sh            build a release .app into ./build/
#   ./bundle.sh --install  also copy it into /Applications
#   ./bundle.sh --run      also launch it when done
set -euo pipefail

cd "$(dirname "$0")"
ROOT="$(pwd)"
APP_NAME="GlassTime"
BUILD_DIR="$ROOT/build"
APP="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP/Contents"

echo "▸ Compiling release binary…"
swift build -c release

echo "▸ Assembling $APP_NAME.app…"
rm -rf "$APP"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"

cp "$ROOT/.build/release/$APP_NAME" "$CONTENTS/MacOS/$APP_NAME"
cp "$ROOT/App/Info.plist" "$CONTENTS/Info.plist"

# --- App icon ---------------------------------------------------------------
# macOS 26 (Tahoe) needs the new .icon format (Icon Composer) for a real
# Liquid-Glass icon — a plain transparent .icns lands in "squircle jail" with a
# white backing. App/AppIcon.icon is the Icon Composer document; actool compiles
# it into an Assets.car + AppIcon.icns.
echo "▸ Compiling .icon → Assets.car (actool)…"
xcrun actool "$ROOT/App/AppIcon.icon" \
    --compile "$CONTENTS/Resources" \
    --app-icon AppIcon \
    --include-all-app-icons \
    --output-partial-info-plist "$BUILD_DIR/icon-partial.plist" \
    --platform macosx \
    --minimum-deployment-target 26.0 \
    --target-device mac \
    --output-format human-readable-text --errors --warnings >/dev/null

# --- Sign -------------------------------------------------------------------
# Ad-hoc signature ("-") is enough to run locally and survive Gatekeeper for a
# self-built app. Swap in a Developer ID identity here for distribution.
echo "▸ Code signing (ad-hoc)…"
codesign --force --deep --sign - "$APP"
codesign --verify --verbose "$APP" 2>&1 | sed 's/^/  /'

echo "✓ Built $APP"

if [[ "${1:-}" == "--install" ]]; then
    echo "▸ Installing to /Applications…"
    rm -rf "/Applications/$APP_NAME.app"
    cp -R "$APP" "/Applications/$APP_NAME.app"
    echo "✓ Installed /Applications/$APP_NAME.app"
fi

if [[ "${1:-}" == "--run" ]]; then
    open "$APP"
fi
