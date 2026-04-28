#!/usr/bin/env bash

FILE="$1"

if [ ! -f "$FILE" ]; then
    echo "File not found: $FILE"
    exit 1
fi

MAGIC=$(xxd -p -l 4 "$FILE")

case "$MAGIC" in
    27051956)
        echo "android-sparse"
        ;;
    53ef0000|53ef)
        echo "ext4"
        ;;
    1f8b0800)
        echo "gzip"
        ;;
    414d4c*)
        echo "amlogic-bootloader"
        ;;
    *)
        echo "unknown"
        ;;
esac

