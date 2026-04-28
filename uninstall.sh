#!/usr/bin/env bash

set -e

APP_NAME="Amlogic Firmware Tool"
INSTALL_DIR="/opt/aml-firmware-tool"
DESKTOP_FILE="/usr/share/applications/AmlogicFirmwareTool.desktop"
ICON_FILE="/usr/share/icons/amlogic.png"

echo "🗑 Uninstalling $APP_NAME..."

# Remove install directory
if [ -d "$INSTALL_DIR" ]; then
    echo "Removing $INSTALL_DIR..."
    sudo rm -rf "$INSTALL_DIR"
else
    echo "Directory not found: $INSTALL_DIR"
fi

# Remove desktop launcher
if [ -f "$DESKTOP_FILE" ]; then
    echo "Removing desktop entry..."
    sudo rm -f "$DESKTOP_FILE"
else
    echo "Desktop entry not found: $DESKTOP_FILE"
fi

# Remove icon
if [ -f "$ICON_FILE" ]; then
    echo "Removing icon..."
    sudo rm -f "$ICON_FILE"
else
    echo "Icon not found: $ICON_FILE"
fi

echo "✔ Uninstallation complete."
echo "All components of '$APP_NAME' have been removed."
