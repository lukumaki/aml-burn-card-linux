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
if [[ "$MAGIC" == 414d4c55* ]] || [[ "$MAGIC" == 414d4c42* ]]; then
    echo "amlogic-upgrade-package"
    exit 2
fi

#----------------------------------------------------------
# 2) Detect RAW DISK IMAGES (ALLOW)
#----------------------------------------------------------

# MBR signature (offset 510)
MBR_SIG=$(xxd -p -s 510 -l 2 "$FILE")
if [[ "$MBR_SIG" == "55aa" ]]; then
    echo "raw-disk-image"
    exit 0
fi

# GPT signature (offset 512)
GPT_SIG=$(xxd -p -s 512 -l 8 "$FILE")
if [[ "$GPT_SIG" == "4546492050415254" ]]; then
    echo "raw-disk-image"
    exit 0
fi

# EXT4 magic (offset 1080)
EXT4=$(xxd -p -s 1080 -l 2 "$FILE")
if [[ "$EXT4" == "53ef" ]]; then
    echo "raw-disk-image"
    exit 0
fi

# SQUASHFS magic
if [[ "$MAGIC" == "68737173"* ]]; then
    echo "raw-disk-image"
    exit 0
fi

# U-Boot FIT image
if [[ "$MAGIC" == "27051956"* ]]; then
    echo "raw-disk-image"
    exit 0
fi

#----------------------------------------------------------
# 3) Not a firmware (REJECT)
#----------------------------------------------------------
echo "not-firmware"
exit 1
