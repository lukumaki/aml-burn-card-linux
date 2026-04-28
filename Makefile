# ---------------------------------------------------------
#  Makefile for Amlogic Firmware Tool
#  Provides: make install / make uninstall / make build
# ---------------------------------------------------------

APP_NAME = Amlogic Firmware Tool
INSTALL_DIR = /opt/aml-firmware-tool
DESKTOP_FILE = /usr/share/applications/AmlogicFirmwareTool.desktop
ICON_FILE = /usr/share/icons/amlogic.png

# ---------------------------------------------------------
#  Default target
# ---------------------------------------------------------
all:
    @echo "Available targets:"
    @echo "  make install     - Install the tool system-wide"
    @echo "  make uninstall   - Remove the tool"
    @echo "  make build       - Build simg2img from source"
    @echo "  make clean       - Remove build artifacts"

# ---------------------------------------------------------
#  Install the tool
# ---------------------------------------------------------
install:
    @echo "🔧 Installing $(APP_NAME)..."
    sudo bash install.sh
    @echo "✔ Installation complete."

# ---------------------------------------------------------
#  Uninstall the tool
# ---------------------------------------------------------
uninstall:
    @echo "🗑 Uninstalling $(APP_NAME)..."
    sudo bash uninstall.sh
    @echo "✔ Uninstallation complete."

# ---------------------------------------------------------
#  Build simg2img from source (optional helper)
# ---------------------------------------------------------
build:
    @echo "🔨 Building simg2img from source..."
    mkdir -p tools
    cd tools && \
        ( [ -d android-simg2img ] || git clone https://github.com/anestisb/android-simg2img.git ) && \
        cd android-simg2img && \
        make clean || true && \
        make && \
        cp simg2img ../simg2img && \
        chmod +x ../simg2img
    @echo "✔ simg2img built successfully."

# ---------------------------------------------------------
#  Clean build artifacts
# ---------------------------------------------------------
clean:
    @echo "🧹 Cleaning build artifacts..."
    rm -f tools/simg2img
    rm -rf tools/android-simg2img
    @echo "✔ Clean complete."
