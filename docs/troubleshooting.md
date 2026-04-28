# 🛠️ Troubleshooting Guide  

This guide helps diagnose and resolve common problems when using the Amlogic Firmware Tool on Linux systems.

---

## ❗ 1. "permission denied" when running the tool

### **Cause**
The script is not marked as executable.

### **Fix**
Run:

```bash
chmod +x amlogic_firmware_tool.sh
chmod +x install.sh uninstall.sh
chmod +x tools/* 2>/dev/null
```

If installed system‑wide:

```bash
sudo chmod +x /opt/aml-firmware-tool/*.sh
```

---

## ❗ 2. simg2img missing or not found

### **Cause**
The binary is not present in `tools/` or not executable.

### **Fix**
The tool auto‑builds simg2img, but you can force a rebuild:

```bash
make build
```

Or manually:

```bash
cd tools
git clone https://github.com/anestisb/android-simg2img.git
cd android-simg2img
make
cp simg2img ../
chmod +x ../simg2img
```

---

## ❗ 3. "fatal error: zlib.h: No such file or directory"

### **Cause**
Missing zlib development headers required for building simg2img.

### **Fix**

```bash
sudo apt install libz-dev
```

Then rebuild:

```bash
make build
```

---

## ❗ 4. "mount: only root can do that"

### **Cause**
Mounting loop devices requires root privileges.

### **Fix**
Run the tool with sudo:

```bash
sudo amlogic_firmware_tool.sh firmware.img
```

---

## ❗ 5. "losetup: command not found"

### **Cause**
`losetup` is part of the `util-linux` package.

### **Fix**

```bash
sudo apt install util-linux
```

---

## ❗ 6. "xxd: command not found"

### **Cause**
`xxd` is missing (used for magic-byte detection).

### **Fix**

```bash
sudo apt install xxd
```

---

## ❗ 7. "python3: command not found"

### **Cause**
Python 3 is missing (required for outer Amlogic unpacking).

### **Fix**

```bash
sudo apt install python3
```

---

## ❗ 8. Outer firmware not unpacking

### **Possible causes**
- Corrupted firmware file  
- Unsupported Amlogic container  
- Missing Python dependencies  

### **Fix**
Try running the Python script directly:

```bash
python3 unpack_amlogic_outer.py firmware.img
```

If it prints an error, include the output when reporting a bug.

---

## ❗ 9. Sparse image not converting to ext4

### **Cause**
`simg2img` failed or the image is not sparse.

### **Fix**
Check the magic bytes:

```bash
tools/verify_magic.sh system.img
```

Expected outputs:

- `android-sparse` → should convert  
- `ext4` → already raw  
- `gzip` → decompress first  
- `unknown` → unsupported format  

---

## ❗ 10. "File not found" errors

### **Cause**
The firmware path contains spaces or special characters.

### **Fix**
Wrap the path in quotes:

```bash
amlogic_firmware_tool.sh "My Firmware/firmware.img"
```

---

## ❗ 11. Desktop launcher not appearing

### **Cause**
Some desktop environments require a refresh.

### **Fix**

```bash
sudo update-desktop-database
```

Or log out and back in.

---

## ❗ 12. Uninstall did not remove everything

### **Cause**
Files may have been modified manually.

### **Fix**
Remove manually:

```bash
sudo rm -rf /opt/aml-firmware-tool
sudo rm -f /usr/share/applications/AmlogicFirmwareTool.desktop
sudo rm -f /usr/share/icons/amlogic.png
```

---

## 🧩 Need more help?

If you encounter an issue not listed here, open a GitHub issue and include:

- Your Linux distribution  
- The firmware file name  
- The full terminal output  
- The contents of `logs/` (if generated)  

This helps diagnose the problem quickly.
