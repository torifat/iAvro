#!/bin/bash
# Deploy the debug build to ~/Library/Input Methods and relaunch.

set -e

APP_NAME="Avro Keyboard"
INSTALL_DIR="$HOME/Library/Input Methods"

# Find the most recently modified DerivedData build.
BUILD=$(ls -td ~/Library/Developer/Xcode/DerivedData/AvroKeyboard-*/Build/Products/Debug/"$APP_NAME.app" 2>/dev/null | head -1)

if [ -z "$BUILD" ]; then
    echo "Error: No debug build found. Build in Xcode first." >&2
    exit 1
fi

killall "$APP_NAME" 2>/dev/null || true
sleep 0.5

cp -R "$BUILD" "$INSTALL_DIR/"

open "$INSTALL_DIR/$APP_NAME.app"

echo "Deployed and relaunched '$APP_NAME'."
