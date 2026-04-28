#!/usr/bin/env python3
import sys
import os
import struct
import subprocess
import shutil

RECORD_SIZE = 0x240
BASE_OFFSET = 0x40

SPARSE_MAGIC = 0xED26FF3A

def read_u32_le(buf, off):
    if off + 4 > len(buf):
        raise ValueError(f"u32_le out of range at 0x{off:x}")
    return struct.unpack_from("<I", buf, off)[0]

def is_sparse_image(path):
    try:
        with open(path, "rb") as f:
            magic = struct.unpack("<I", f.read(4))[0]
        return magic == SPARSE_MAGIC
    except Exception:
        return False

def convert_sparse_to_raw(src, dst):
    simg2img = shutil.which("simg2img")
    if not simg2img:
        print(f"[!] simg2img not found, leaving sparse image as-is: {src}")
        return False
    print(f"[+] Converting sparse → raw: {src} -> {dst}")
    subprocess.check_call([simg2img, src, dst])
    return True

def unpack_outer(img_path, out_dir):
    with open(img_path, "rb") as f:
        data = f.read()

    if len(data) < 0x19:
        print("File too small to be a valid Amlogic upgrade image")
        sys.exit(1)

    record_count = data[0x18]
    print(f"[+] Record count: {record_count}")

    for record in range(record_count):
        record_loc = BASE_OFFSET + record * RECORD_SIZE
        if record_loc + RECORD_SIZE > len(data):
            print(f"[!] Record {record} header out of bounds, stopping")
            break

        name_off = record_loc + 0x120
        ext_off  = record_loc + 0x20

        name = data[name_off:name_off+32].split(b"\x00", 1)[0].decode(errors="ignore")
        ext  = data[ext_off:ext_off+8].split(b"\x00", 1)[0].decode(errors="ignore")

        if not name:
            print(f"[!] Empty name at record {record}, skipping")
            continue

        filename = f"{name}.{ext}" if ext else name
        filename = filename.strip().replace("/", "_")

        file_loc  = read_u32_le(data, record_loc + 0x10)
        file_size = read_u32_le(data, record_loc + 0x18)

        if file_loc + file_size > len(data):
            print(f"[!] Record {record}: {filename} out of bounds (loc=0x{file_loc:x}, size=0x{file_size:x})")
            continue

        out_path = os.path.join(out_dir, filename)
        print(f"[+] Extracting {filename} (0x{file_loc:x} .. 0x{file_loc+file_size:x})")

        with open(out_path, "wb") as out_f:
            out_f.write(data[file_loc:file_loc+file_size])

    print("[+] Outer unpack done.")

def extract_partitions(out_dir):
    part_dir = os.path.join(out_dir, "partitions")
    os.makedirs(part_dir, exist_ok=True)

    for entry in os.listdir(out_dir):
        if not entry.endswith(".PARTITIO"):
            continue
        src = os.path.join(out_dir, entry)
        base = entry.rsplit(".", 1)[0]
        raw_target = os.path.join(part_dir, base + ".img")

        print(f"[+] Processing partition descriptor: {entry}")

        # For many Amlogic packages, .PARTITIO is already the raw image
        # but we still check for sparse format.
        if is_sparse_image(src):
            tmp_raw = raw_target + ".raw"
            if convert_sparse_to_raw(src, tmp_raw):
                os.replace(tmp_raw, raw_target)
            else:
                # leave original as-is
                shutil.copy2(src, raw_target)
        else:
            shutil.copy2(src, raw_target)

    print("[+] Partition extraction phase done.")

def main():
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <firmware.img> <output_dir>")
        sys.exit(1)

    img_path = sys.argv[1]
    out_dir = sys.argv[2]

    os.makedirs(out_dir, exist_ok=True)

    unpack_outer(img_path, out_dir)
    extract_partitions(out_dir)

if __name__ == "__main__":
    main()

