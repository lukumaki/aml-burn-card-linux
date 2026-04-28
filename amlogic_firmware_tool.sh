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

