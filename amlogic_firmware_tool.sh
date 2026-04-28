#!/usr/bin/env bash
set -euo pipefail

LOGFILE="amlogic_tool.log"
MOUNT="/mnt/aml"

echo "=== Amlogic Firmware → Bootable SD Creator ==="
echo "Log file: $LOGFILE"
echo

log() {
    echo "$@" | tee -a "$LOGFILE"
}

# ---------------------------------------------------------
#  Dependency checks and auto-install/build helpers
# ---------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOOLS_DIR="$SCRIPT_DIR/tools"
SIMG2IMG="$TOOLS_DIR/simg2img"
VERIFY_MAGIC="$TOOLS_DIR/verify_magic.sh"

# Ensure tools directory exists
mkdir -p "$TOOLS_DIR"

# -----------------------------
# Check for required commands
# -----------------------------
require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "❌ Missing required command: $1"
        echo "   Please install it using your package manager."
        exit 1
    fi
}

echo "🔍 Checking system dependencies..."

require_cmd xxd
require_cmd python3
require_cmd gunzip
require_cmd losetup
require_cmd mount

echo "✔ Base system dependencies OK."

# ---------------------------------------------------------
#  Auto-detect verify_magic.sh
# ---------------------------------------------------------
check_verify_magic() {
    if [ -x "$VERIFY_MAGIC" ]; then
        echo "✔ verify_magic.sh found."
        return
    fi

    echo "⚠ verify_magic.sh missing. Creating default version..."

    cat << 'EOF' > "$VERIFY_MAGIC"
#!/usr/bin/env bash
FILE="$1"
if [ ! -f "$FILE" ]; then
    echo "File not found: $FILE"
    exit 1
fi
MAGIC=$(xxd -p -l 4 "$FILE")
case "$MAGIC" in
    27051956) echo "android-sparse" ;;
    53ef0000|53ef) echo "ext4" ;;
    1f8b0800) echo "gzip" ;;
    414d4c*) echo "amlogic-bootloader" ;;
    *) echo "unknown" ;;
esac
EOF

    chmod +x "$VERIFY_MAGIC"
    echo "✔ verify_magic.sh created."
}

check_verify_magic

# ---------------------------------------------------------
#  Auto-detect or build simg2img from source
# ---------------------------------------------------------
check_simg2img() {
    if [ -x "$SIMG2IMG" ]; then
        echo "✔ simg2img found."
        return
    fi

    echo "⚠ simg2img not found. Building from source..."

    sudo apt-get update
    sudo apt-get install -y build-essential git libz-dev

    cd "$TOOLS_DIR"

    if [ ! -d "android-simg2img" ]; then
        git clone https://github.com/anestisb/android-simg2img.git
    fi

    cd android-simg2img

    make clean || true
    make

    cp simg2img "$SIMG2IMG"
    chmod +x "$SIMG2IMG"

    echo "✔ simg2img built and installed."
}

check_simg2img

echo "🎉 All dependencies satisfied."
echo

# ---------------------------------------------------------
# Optional: restore SD card to normal mode
# ---------------------------------------------------------
if [[ "${1-}" == "restore" ]]; then
    log "[*] RESTORE MODE: restore SD card to normal single FAT32"
    lsblk -o NAME,SIZE,MODEL,TYPE | tee -a "$LOGFILE"
    echo
    log "Select device to restore:"
    mapfile -t DEVICES < <(lsblk -dpno NAME,TYPE | awk '$2=="disk"{print $1}')
    select DEVICE in "${DEVICES[@]}"; do
        [[ -n "$DEVICE" ]] && break
    done
    read -rp "Type YES to confirm wiping $DEVICE: " confirm
    [[ "$confirm" != "YES" ]] && { log "Aborted."; exit 1; }

    log "[1/2] Wiping beginning of device..."
    sudo dd if=/dev/zero of="$DEVICE" bs=1M count=10 conv=fsync | tee -a "$LOGFILE"

    log "[2/2] Creating single FAT32 partition..."
    sudo parted "$DEVICE" --script mklabel msdos
    sudo parted "$DEVICE" --script mkpart primary fat32 1MiB 100%
    sudo mkfs.vfat -n SDCARD "${DEVICE}1"

    log "Restore complete."
    exit 0
fi

# ---------------------------------------------------------
# STEP 1 — Select firmware IMG to unpack
# ---------------------------------------------------------
log "[*] Scanning for firmware images..."
mapfile -t IMGS < <(ls *.img 2>/dev/null || true)

if [[ ${#IMGS[@]} -eq 0 ]]; then
    log "ERROR: No .img firmware files found."
    exit 1
fi

log "Select firmware to unpack:"
select FWIMG in "${IMGS[@]}"; do
    [[ -n "$FWIMG" ]] && break
done
log "[+] Selected firmware: $FWIMG"

# SHA256
if command -v sha256sum >/dev/null 2>&1; then
    log "[*] Calculating SHA256..."
    sha256sum "$FWIMG" | tee -a "$LOGFILE"
else
    log "[!] sha256sum not found, skipping checksum."
fi

# Basic sanity check
if [[ ! -s "$FWIMG" ]]; then
    log "ERROR: Firmware file is empty or unreadable."
    exit 1
fi

OUTDIR="unpacked_${FWIMG%.img}"
mkdir -p "$OUTDIR"

echo
log "[*] Unpacking firmware using Python tool..."
python3 unpack_amlogic_outer.py "$FWIMG" "$OUTDIR" | tee -a "$LOGFILE"

echo
log "[*] Searching for burn-card files in $OUTDIR..."

UBOOT_FILE=$(ls "$OUTDIR"/aml_sdc_burn.UBOOT 2>/dev/null || true)
INI_FILE=$(ls "$OUTDIR"/aml_sdc_burn.ini 2>/dev/null || true)

if [[ -z "$UBOOT_FILE" || -z "$INI_FILE" ]]; then
    log "ERROR: Burn files not found in unpacked output."
    exit 1
fi

log "Found:"
log " - $UBOOT_FILE"
log " - $INI_FILE"

# ---------------------------------------------------------
# STEP 2 — Select SD device
# ---------------------------------------------------------
echo
log "[*] Detecting block devices..."
lsblk -o NAME,SIZE,MODEL,TYPE | tee -a "$LOGFILE"
echo

log "Select target device:"
mapfile -t DEVICES < <(lsblk -dpno NAME,TYPE | awk '$2=="disk"{print $1}')
select DEVICE in "${DEVICES[@]}"; do
    [[ -n "$DEVICE" ]] && break
done
log "[+] Selected device: $DEVICE"

echo
read -rp "Type YES to confirm wiping $DEVICE: " confirm
[[ "$confirm" != "YES" ]] && { log "Aborted."; exit 1; }

# ---------------------------------------------------------
# STEP 3 — Mode selection
# ---------------------------------------------------------
echo
log "Choose operation mode:"
select MODE in "Normal" "Dry-run" "Verify-only"; do
    case $MODE in
        Normal) log "[+] Normal mode selected"; break ;;
        Dry-run) log "[+] Dry-run mode selected"; break ;;
        Verify-only) log "[+] Verification mode selected"; break ;;
    esac
done

# ---------------------------------------------------------
# STEP 4 — Verification-only mode
# ---------------------------------------------------------
if [[ "$MODE" == "Verify-only" ]]; then
    echo
    log "=== VERIFICATION REPORT ==="
    log "Firmware: $FWIMG"
    log "Unpacked directory: $OUTDIR"
    log "Bootloader: $UBOOT_FILE"
    log "INI file: $INI_FILE"
    log "Target device: $DEVICE"
    log "Partitions dir (if any): $OUTDIR/partitions"
    log "No changes made."
    exit 0
fi

# ---------------------------------------------------------
# STEP 5 — Dry-run mode
# ---------------------------------------------------------
if [[ "$MODE" == "Dry-run" ]]; then
    echo
    log "=== DRY RUN ==="
    log "Would wipe: $DEVICE"
    log "Would write bootloader: $UBOOT_FILE"
    log "Would create FAT32 partition"
    log "Would copy:"
    log "   - $INI_FILE"
    log "   - $FWIMG → aml_upgrade_package.img"
    log "No changes made."
    exit 0
fi

# ---------------------------------------------------------
# STEP 6 — NORMAL MODE: Create bootable SD
# ---------------------------------------------------------
echo
log "[1/5] Wiping beginning of device..."
sudo dd if=/dev/zero of="$DEVICE" bs=1M count=10 conv=fsync | tee -a "$LOGFILE"

log "[2/5] Writing Amlogic burn bootloader..."
sudo dd if="$UBOOT_FILE" of="$DEVICE" bs=512 seek=1 conv=fsync | tee -a "$LOGFILE"

log "[3/5] Creating partition table..."
sudo parted "$DEVICE" --script mklabel msdos
sudo parted "$DEVICE" --script mkpart primary fat32 1MiB 100%

log "[4/5] Formatting FAT32..."
sudo mkfs.vfat -n AMLOGIC "${DEVICE}1"

log "[5/5] Copying files..."
sudo mkdir -p "$MOUNT"
sudo mount "${DEVICE}1" "$MOUNT"

sudo cp "$INI_FILE" "$MOUNT/"
sudo cp "$FWIMG" "$MOUNT/aml_upgrade_package.img"

sync
sudo umount "$MOUNT"

log "=== DONE ==="
log "Your Amlogic recovery SD card is ready."
log "Use the toothpick method to start flashing."

