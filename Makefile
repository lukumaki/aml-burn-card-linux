# ---------------------------------------------------------
#  Makefile for Amlogic Burn Card Tool
# ---------------------------------------------------------

APP_NAME = Amlogic Burn Card Tool
INSTALL_DIR = /opt/aml-burn-card-tool

# ---------------------------------------------------------
#  Default target
# ---------------------------------------------------------
all:

	@echo "Available targets:"
	@echo "make install     - Install the tool system-wide"
	@echo "make uninstall   - Remove the tool"
	@echo "make build       - Build simg2img from source"
	@echo "make clean       - Remove build artifacts"

# ---------------------------------------------------------
#  Install the tool
# ---------------------------------------------------------
install:
	sudo bash install.sh

# ---------------------------------------------------------
#  Uninstall the tool
# ---------------------------------------------------------
uninstall:
	sudo bash uninstall.sh

# ---------------------------------------------------------
#  Build simg2img from source
# ---------------------------------------------------------
build:
	mkdir -p tools
	cd tools && \
	( [ -d android-simg2img ] || git clone https://github.com/anestisb/android-simg2img.git ) && \
	cd android-simg2img && \
	make clean || true && \
	make && \
	cp simg2img ../simg2img && \
	chmod +x ../simg2img

# ---------------------------------------------------------
#  Clean build artifacts
# ---------------------------------------------------------
clean:
	rm -f tools/simg2img
	rm -rf tools/android-simg2img
