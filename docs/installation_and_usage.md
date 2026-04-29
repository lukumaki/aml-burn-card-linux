# 📄 Installation & Usage Guide

This document explains how to install, uninstall, and use the Amlogic Firmware Tool on Linux systems (Linux Mint, Ubuntu, Debian, Pop!_OS, etc.).
The tool extracts, inspects, and processes Amlogic Android firmware images, including sparse/ext4 partitions and outer Amlogic containers.
   
The following system utilities must be available, usually these are normally preinstalled on most Linux distributions:
- xxd
- python3
- gunzip
- losetup
- mount

The tool will also automatically install required packages in order to build `simg2img` from source, and create `verify_magic.sh`.
packages (`build-essential`, `git`, `libz-dev`) will also be installed when needed. No manual setup is required.  

---

## 📦 Getting the Source Code

Before using the installer or the Makefile, you must clone the repository locally:
```bash
git clone https://github.com/lukumaki/aml-burn-card-linux.git
cd aml-burn-card-linux
```
---
## 🛠️ Installation

### Method A — Using the installer (recommended)
From inside the project directory:
```
sudo bash install.sh
```
This will:
- install the tool into /opt/aml-firmware-tool/
- install the desktop launcher
- install the application icon
- ensure all scripts are executable
- prepare the environment for first use

After installation, you can launch the tool from the application menu or by running:
```
amlogic_firmware_tool.sh
```
### Method B — Using Makefile
If you prefer a cleaner workflow:
```
make install
```
This runs the same installer with proper permissions.

---
## 🗑️ Uninstallation
To remove the tool completely:
```
sudo bash uninstall.sh
```
or:
```
make uninstall
```
This removes:
- `/opt/aml-firmware-tool/`
- `/usr/share/applications/AmlogicFirmwareTool.desktop`
- `/usr/share/icons/amlogic.png`
No leftover files remain.  
---
## ⚙️ What the tool does automatically
1) Basic extraction
```
amlogic_firmware_tool.sh firmware.img
```
This will:
- detect the firmware type
- unpack the outer Amlogic container
- detect partition formats
- convert sparse → ext4
- extract filesystem contents
- organize output into folders
2) Specify output directory
```
amlogic_firmware_tool.sh -o output_dir firmware.img
```
Verbose mode
```
amlogic_firmware_tool.sh -v firmware.img
```  
3) Overall:
- Detects missing dependencies
- Builds simg2img from source if needed
- Creates verify_magic.sh if missing
- Detects sparse/ext4/gzip/bootloader partitions
- Extracts Amlogic outer containers
- Organizes extracted partitions into clean folders
---
## 💡 File Locations
| Component | Path |
| --- | --- |
| Installation directory | ``/opt/aml-firmware-tool/`` |
| Desktop launcher | ``/usr/share/applications/AmlogicFirmwareTool.desktop`` |
| Icon | ``/usr/share/icons/amlogic.png`` |
| Man page (optional) | ``/usr/share/man/man1/amlogic-firmware-tool.1.gz`` |
