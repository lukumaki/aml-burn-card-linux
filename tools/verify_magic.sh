#!/usr/bin/env bash
set -euo pipefail

FILE="$1"

if [[ ! -f "$FILE" ]]; then
    echo "error-file-not-found"
    exit 1
fi

# Read first 8 bytes
MAGIC=$(xxd -p -l 8 "$FILE")

#----------------------------------------------------------
# 1) Detect Amlogic Android Upgrade Packages (REJECT)
#----------------------------------------------------------
# These start with:
#   AMLU....  (41 4D 4C 55)
#   AMLB....  (41 4D 4C 42)
# These CANNOT be flashed with dd.
#----------------------------------------------------------
if [[ "$MAGIC" == 414d4c55* ]] || [[ "$MAGIC" == 414d4c42* ]]; then
    echo "amlogic-upgrade-package"
    exit 2
fi

#----------------------------------------------------------
# 2) Detect RAW DISK IMAGES (ALLOW)
#----------------------------------------------------------
# Burn-card images ALWAYS contain:
#   - MBR signature: 55 AA at offset 510
#   - OR GPT header: "EFI PART" at offset 512
#----------------------------------------------------------

# Check for MBR (offset 510)
MBR_SIG=$(xxd -p -s 510 -l 2 "$FILE")
if [[ "$MBR_SIG" == "55aa" ]]; then
    echo "raw-disk-image"
    exit 0
fi

# Check for GPT (offset 512)
GPT_SIG=$(xxd -p -s 512 -l 8 "$FILE")
if [[ "$GPT_SIG" == "4546492050415254" ]]; then
    echo "raw-disk-image"
    exit 0
fi

#----------------------------------------------------------
# 3) Detect EXT4 / SQUASHFS / UBIFS / U-Boot (ALLOW)
#----------------------------------------------------------

# EXT4 magic at offset 0x438
EXT4=$(xxd -p -s 1080 -l 2 "$FILE")
if [[ "$EXT4" == "53ef" ]]; then
    echo "raw-disk-image"
    exit 0
fi

# SQUASHFS magic: 68 73 71 73
if [[ "$MAGIC" == "68737173"* ]]; then
    echo "raw-disk-image"
    exit 0
fi

# U-Boot FIT images: 27 05 19 56
if [[ "$MAGIC" == "27051956"* ]]; then
    echo "raw-disk-image"
    exit 0
fi

#----------------------------------------------------------
# 4) If nothing matched → NOT a firmware
#----------------------------------------------------------
echo "not-firmware"
exit 1
