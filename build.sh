#!/usr/bin/env bash
# build.sh — builds EyeBreak and packages it as EyeBreak.app
set -euo pipefail

BINARY_NAME="EyeBreak"
APP_NAME="EyeBreak.app"
BUILD_CONFIG="release"

echo "==> Building Swift package (${BUILD_CONFIG})…"
swift build -c "${BUILD_CONFIG}"

BINARY_PATH=".build/${BUILD_CONFIG}/${BINARY_NAME}"

if [ ! -f "${BINARY_PATH}" ]; then
    echo "ERROR: Binary not found at ${BINARY_PATH}"
    exit 1
fi

echo "==> Creating .app bundle…"
APP_CONTENTS="${APP_NAME}/Contents"
rm -rf "${APP_NAME}"
mkdir -p "${APP_CONTENTS}/MacOS"
mkdir -p "${APP_CONTENTS}/Resources"

cp "${BINARY_PATH}"       "${APP_CONTENTS}/MacOS/${BINARY_NAME}"
cp "Resources/Info.plist" "${APP_CONTENTS}/Info.plist"

# Ad-hoc code signing is required on macOS 13+ for UNUserNotificationCenter
# to show the permission dialog. The "-" identity means no developer certificate
# is needed — this is sufficient for local use.
echo "==> Ad-hoc signing…"
codesign --force --deep --sign - "${APP_NAME}"

echo "==> Done!"
echo ""
echo "  App bundle: $(pwd)/${APP_NAME}"
echo ""
echo "To launch:"
echo "  open ${APP_NAME}"
echo ""
echo "To install system-wide (optional):"
echo "  cp -R ${APP_NAME} /Applications/"
echo "  open /Applications/${APP_NAME}"
echo ""
echo "To add to Login Items:"
echo "  System Settings → General → Login Items → add EyeBreak"
