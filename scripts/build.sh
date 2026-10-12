#!/bin/bash
# Build Avro Keyboard.app for Apple Silicon (arm64) using Command Line Tools.
# Usage: ./scripts/build.sh [--install]

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="${ROOT}/build"
APP_NAME="Avro Keyboard"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"
CONTENTS="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS}/MacOS"
RESOURCES="${CONTENTS}/Resources"
INSTALL_DIR="${HOME}/Library/Input Methods"

SDK="$(xcrun --show-sdk-path)"
MACOSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET:-13.0}"
BUNDLE_ID="com.omicronlab.inputmethod.AvroKeyboard"

echo "==> Cleaning ${BUILD_DIR}"
rm -rf "${BUILD_DIR}"
mkdir -p "${MACOS_DIR}" "${RESOURCES}"

PLUGIN_PATH="$(dirname "$(xcrun --find swiftc)")/../lib/swift/host/plugins"

echo "==> Compiling Swift sources (arm64)"
# shellcheck disable=SC2046
swiftc \
  -sdk "${SDK}" \
  -target "arm64-apple-macosx${MACOSX_DEPLOYMENT_TARGET}" \
  -O \
  -plugin-path "${PLUGIN_PATH}" \
  -framework Cocoa \
  -framework InputMethodKit \
  -framework SwiftUI \
  -lsqlite3 \
  -o "${MACOS_DIR}/${APP_NAME}" \
  $(find "${ROOT}/Sources" -name '*.swift' | sort)

echo "==> Writing Info.plist"
cat > "${CONTENTS}/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>English</string>
	<key>CFBundleExecutable</key>
	<string>${APP_NAME}</string>
	<key>CFBundleIdentifier</key>
	<string>${BUNDLE_ID}</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>${APP_NAME}</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>1.5</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>CFBundleIconFile</key>
	<string>AppIcon</string>
	<key>LSMinimumSystemVersion</key>
	<string>${MACOSX_DEPLOYMENT_TARGET}</string>
	<key>LSBackgroundOnly</key>
	<true/>
	<key>InputMethodConnectionName</key>
	<string>Avro_Keyboard_Connection</string>
	<key>InputMethodServerControllerClass</key>
	<string>AvroKeyboardController</string>
	<key>NSMainNibFile</key>
	<string>MainMenu</string>
	<key>NSPrincipalClass</key>
	<string>NSApplication</string>
	<key>NSSupportsSuddenTermination</key>
	<false/>
	<key>TISIntendedLanguage</key>
	<string>bn</string>
	<key>tsInputMethodCharacterRepertoireKey</key>
	<array>
		<string>Beng</string>
	</array>
	<key>tsInputMethodIconFileKey</key>
	<string>MenuIcon</string>
</dict>
</plist>
EOF

echo "==> Copying resources"
cp "${ROOT}/database.db3" "${RESOURCES}/"
cp "${ROOT}/regex.json" "${RESOURCES}/"
cp "${ROOT}/data.json" "${RESOURCES}/"
cp "${ROOT}/autodict.plist" "${RESOURCES}/"
cp "${ROOT}/preferences.plist" "${RESOURCES}/"
cp -R "${ROOT}/Credits.rtfd" "${RESOURCES}/"
cp -R "${ROOT}/English.lproj" "${RESOURCES}/"
cp "${ROOT}/Icons/AutoCorrect.png" "${RESOURCES}/"
cp "${ROOT}/Icons/Credits.png" "${RESOURCES}/"
cp "${ROOT}/Icons/General.png" "${RESOURCES}/"

# Menu bar icon (referenced by tsInputMethodIconFileKey)
cp "${ROOT}/Images.xcassets/MenuIcon.imageset/final16flat2.png" "${RESOURCES}/MenuIcon.png"

# App icon — sips can produce .icns without a full iconset
sips -s format icns \
  "${ROOT}/Images.xcassets/AppIcon.appiconset/final512_flat.png" \
  --out "${RESOURCES}/AppIcon.icns" >/dev/null

echo "==> Ad-hoc signing"
codesign --force --deep --sign - "${APP_BUNDLE}"

echo "==> Built: ${APP_BUNDLE}"
file "${MACOS_DIR}/${APP_NAME}"
lipo -info "${MACOS_DIR}/${APP_NAME}"

if [[ "${1:-}" == "--install" ]]; then
  echo "==> Installing to ${INSTALL_DIR}"
  mkdir -p "${INSTALL_DIR}"
  killall "${APP_NAME}" 2>/dev/null || true
  sleep 0.5
  rm -rf "${INSTALL_DIR}/${APP_NAME}.app"
  cp -R "${APP_BUNDLE}" "${INSTALL_DIR}/"
  echo "Installed. Enable it in System Settings → Keyboard → Input Sources → Avro Keyboard"
  echo "Then switch away from Avro and back (or log out/in) to load it."
fi
