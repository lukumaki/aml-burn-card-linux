#!/usr/bin/env bash
set -euo pipefail

#===========================================================
# Amlogic Burn Card Tool (Linux)
#===========================================================

# Self-elevate if not root
if [[ $EUID -ne 0 ]]; then
    exec sudo bash "$0" "$@"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGFILE="$SCRIPT_DIR/amlogic_firmware_tool.log"
VERIFY_MAGIC="$SCRIPT_DIR/tools/verify_magic.sh"

#-----------------------------
# Colors (with fallback)
#-----------------------------
if command -v tput >/dev/null 2>&1 && [[ -n "${TERM-}" ]]; then
    RED="$(tput setaf 1 || true)"
    GREEN="$(tput setaf 2 || true)"
    YELLOW="$(tput setaf 3 || true)"
    BLUE="$(tput setaf 4 || true)"
    BOLD="$(tput bold || true)"
    RESET="$(tput sgr0 || true)"
else
    RED=""; GREEN=""; YELLOW=""; BLUE=""; BOLD=""; RESET=""
fi

#-----------------------------
# Logging helpers
#-----------------------------
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOGFILE"
}

fail() {
    local msg="$*"
    log "${RED}ERROR:${RESET} $msg"
    if command -v zenity >/dev/null 2>&1; then
        zenity --error --title="Amlogic Burn Card Tool" --text="$msg" 2>/dev/null || true
    fi
    exit 1
}

#-----------------------------
# Dependency checks
#-----------------------------
require_cmd() {
    command -v "$1" >/dev/null 2>&1 || fail "Required command '$1' not found."
}

check_dependencies() {
    require_cmd dd
    require_cmd lsblk
    require_cmd grep
    require_cmd awk
    require_cmd sed
    require_cmd mount
    require_cmd umount
    require_cmd xxd
    require_cmd sha256sum
    require_cmd stat

    if ! command -v zenity >/dev/null 2>&1; then
        log "${YELLOW}Notice:${RESET} 'zenity' not found. Falling back to text-based selection."
    fi
}

#-----------------------------
# Firmware selection
#-----------------------------
select_firmware() {
    local firmware="${1-}"

    if [[ -n "$firmware" ]]; then
        [[ -f "$firmware" ]] || fail "Firmware file '$firmware' does not exist."
        echo "$firmware"
        return
    fi

    if command -v zenity >/dev/null 2>&1; then
        firmware="$(zenity --file-selection \
                           --title="Select Firmware Image" \
                           --file-filter="*.img" 2>/dev/null || true)"
        [[ -n "$firmware" ]] || fail "No firmware selected."
        [[ -f "$firmware" ]] || fail "Selected firmware does not exist."
        echo "$firmware"
        return
    fi

    log "${YELLOW}Zenity not available. Using CLI selection.${RESET}"
    read -r -p "Enter path to firmware .img file: " firmware
    [[ -f "$firmware" ]] || fail "Firmware file does not exist."
    echo "$firmware"
}

#-----------------------------
# Firmware verification (uses verify_magic.sh)
#-----------------------------
verify_firmware_magic() {
    local firmware="$1"

    if [[ ! -x "$VERIFY_MAGIC" ]]; then
        fail "verify_magic.sh missing or not executable at: $VERIFY_MAGIC"
    fi

    local output rc
    output="$("$VERIFY_MAGIC" "$firmware" 2>/dev/null || true)"
    rc=$?

    case "$rc" in
        0)
            # raw-disk-image (or allowed type)
            log "${GREEN}Firmware type accepted:${RESET} $output"
            return 0
            ;;
        2)
            # amlogic-upgrade-package (unsupported by dd)
            log "${RED}Unsupported firmware type:${RESET} $output"
            if command -v zenity >/dev/null 2>&1; then
                zenity --error --title="Amlogic Burn Card Tool" \
                       --text="This file is an Amlogic upgrade package and cannot be written with dd.\nUse USB Burning Tool or Burn Card Maker instead." 2>/dev/null || true
            fi
            return 1
            ;;
        1|*)
            # not-firmware or error
            log "${RED}Invalid firmware image:${RESET} $output"
            if command -v zenity >/dev/null 2>&1; then
                zenity --error --title="Amlogic Burn Card Tool" \
                       --text="The selected file does not look like a valid burn-card image.\nDetected: $output" 2>/dev/null || true
            fi
            return 1
            ;;
    esac
}

#-----------------------------
# SD card selection
#-----------------------------
select_sd_device() {
    local devices
    devices="$(lsblk -dpno NAME,SIZE,MODEL,RM | awk '$4 == 1 {print $1 " " $2 " " $3}')"

    [[ -n "$devices" ]] || fail "No removable devices detected."

    if command -v zenity >/dev/null 2>&1; then
        local list=()
        while read -r name size model; do
            list+=("$name" "$size $model")
        done <<< "$devices"

        local selected
        selected="$(zenity --list \
                           --title="Select SD Card Device" \
                           --text="Choose the SD card to write the firmware to.\n${RED}WARNING:${RESET} This will erase all data." \
                           --column="Device" --column="Description" \
                           "${list[@]}" 2>/dev/null || true)"

        [[ -n "$selected" ]] || fail "No SD card selected."
        echo "$selected"
        return
    fi

    log "${BLUE}Available removable devices:${RESET}"
    echo "$devices" | nl -w2 -s": "

    local num
    read -r -p "Enter the number of the SD card device: " num
    local line
    line="$(echo "$devices" | sed -n "${num}p" || true)"
    [[ -n "$line" ]] || fail "Invalid selection."

    echo "$line" | awk '{print $1}'
}

#-----------------------------
# Size check: image vs device
#-----------------------------
check_image_vs_device_size() {
    local firmware="$1"
    local device="$2"

    local img_bytes dev_bytes
    img_bytes="$(stat -c%s "$firmware")"

    if command -v blockdev >/dev/null 2>&1; then
        dev_bytes="$(blockdev --getsize64 "$device")"
    else
        dev_bytes="$(lsblk -bndo SIZE "$device")"
    fi

    if [[ -z "$dev_bytes" ]]; then
        fail "Unable to determine size of device $device."
    fi

    log "Image size:  $img_bytes bytes"
    log "Device size: $dev_bytes bytes"

    if (( img_bytes > dev_bytes )); then
        fail "Firmware image is larger than the target device. Aborting."
    fi
}

#-----------------------------
# Checksum logging
#-----------------------------
log_firmware_checksum() {
    local firmware="$1"
    log "${BLUE}Calculating SHA-256 checksum of firmware...${RESET}"
    local sum
    sum="$(sha256sum "$firmware")"
    log "SHA-256: $sum"
}

#-----------------------------
# Burn card creation
#-----------------------------
create_burn_card() {
    local firmware="$1"
    local device="$2"

    log "${BOLD}About to write firmware:${RESET}"
    log "  Firmware: $firmware"
    log "  Device:   $device"

    check_image_vs_device_size "$firmware" "$device"

    log "${BLUE}Ensuring '$device' is not mounted...${RESET}"
    while read -r mnt; do
        [[ -n "$mnt" ]] || continue
        log "Unmounting $mnt..."
        umount "$mnt" || fail "Failed to unmount $mnt"
    done < <(lsblk -nrpo MOUNTPOINT "$device" | grep -v '^$' || true)

    sync

    log "${YELLOW}Writing firmware image to SD card...${RESET}"
    dd if="$firmware" of="$device" bs=4M status=progress conv=fsync

    sync
    log "${GREEN}Firmware successfully written to '$device'.${RESET}"
}

#-----------------------------
# Main
#-----------------------------
main() {
    : > "$LOGFILE"
    log "${BOLD}Starting Amlogic burn card tool...${RESET}"

    check_dependencies

    local firmware
    firmware="$(select_firmware "${1-}")"
    log "Selected firmware: $firmware"

    log_firmware_checksum "$firmware"

    if ! verify_firmware_magic "$firmware"; then
        fail "Aborting: invalid or unsupported firmware image."
    fi

    local sd_device
    sd_device="$(select_sd_device)"
    log "Selected SD card device: $sd_device"

    create_burn_card "$firmware" "$sd_device"

    log "${GREEN}All done.${RESET}"
}

main "$@"
