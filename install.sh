#!/usr/bin/env bash

set -e

APP_NAME="Amlogic Firmware Tool"
INSTALL_DIR="/opt/aml-firmware-tool"
DESKTOP_FILE="/usr/share/applications/AmlogicFirmwareTool.desktop"
ICON_FILE="/usr/share/icons/amlogic.png"

echo "🔧 Installing $APP_NAME..."

# Create install directory
sudo mkdir -p "$INSTALL_DIR"

# Copy main scripts
sudo cp amlogic_firmware_tool.sh "$INSTALL_DIR/"
sudo cp unpack_amlogic_outer.py "$INSTALL_DIR/"

# Copy tools folder
sudo mkdir -p "$INSTALL_DIR/tools"
sudo cp tools/* "$INSTALL_DIR/tools/"

# Ensure executables
sudo chmod +x "$INSTALL_DIR/amlogic_firmware_tool.sh"
sudo chmod +x "$INSTALL_DIR/unpack_amlogic_outer.py"
sudo chmod +x "$INSTALL_DIR/tools/"*

# Install icon
sudo cp amlogic.png "$ICON_FILE"

# Install desktop launcher
sudo cp AmlogicFirmwareTool.desktop "$DESKTOP_FILE"
sudo chmod +x "$DESKTOP_FILE"

echo "✔ Installation complete!"
echo "You can now launch '$APP_NAME' from your applications menu."

