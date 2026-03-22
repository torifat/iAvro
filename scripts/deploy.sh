#!/bin/bash
# Deploy the debug build to ~/Library/Input Methods.
# After running, switch away from Avro and back to reload.

set -e

APP_NAME="Avro Keyboard"
INSTALL_DIR="$HOME/Library/Input Methods"

# Find the most recently modified DerivedData build.
BUILD=$(ls -td ~/Library/Developer/Xcode/DerivedData/AvroKeyboard-*/Build/Products/Debug/"$APP_NAME.app" 2>/dev/null | head -1)

if [ -z "$BUILD" ]; then
    echo "Error: No debug build found. Build in Xcode first." >&2
    exit 1
fi

# 1. Kill the running process
killall "$APP_NAME" 2>/dev/null || true
sleep 0.5

# 2. Replace with new build (cp -R preserves the Xcode signature)
cp -Rf "$BUILD" "$INSTALL_DIR/"

echo "Deployed '$APP_NAME'. Switch input source away and back to reload."
