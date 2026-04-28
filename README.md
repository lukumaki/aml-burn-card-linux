<h1 align="center">🔥 Amlogic Firmware Tool 🔥</h1>

<p align="center">
  <img src="https://img.shields.io/badge/version-1.0.0-blue.svg" alt="Version">
  <img src="https://img.shields.io/badge/license-MIT-green.svg" alt="License">
  <img src="https://img.shields.io/badge/Linux%20Mint-supported-success.svg" alt="Linux Mint Support">
  <img src="https://img.shields.io/badge/Amlogic-S905X3%20%7C%20S922X%20%7C%20S905X2-orange.svg" alt="Amlogic Support">
  <img src="https://img.shields.io/badge/Architecture-x86__64-lightgrey.svg" alt="Architecture">
</p>

<p align="center">
  Extract • Inspect • Convert • Analyze Amlogic Android Firmware Images  
  <br>
  Fully automated dependency handling • Auto-build simg2img • Clean output structure
</p>

---

## 🔍 Overview
The **Amlogic Firmware Tool** is a Linux-native utility for unpacking, analyzing, and converting Amlogic Android firmware images.  
It automatically detects partition formats, converts sparse images, extracts filesystem contents, and organizes everything into a clean output structure.

Designed for firmware modders, reverse engineers, and embedded Linux enthusiasts.

---

## ✨ Features
- **Full firmware unpacker** (outer container + partitions)
- **Magic-byte detection** for partition type identification
- **Sparse → ext4 conversion** (automatic)
- **Auto-build of** `simg2img` if missing
- **Organized output directories**
- **Desktop launcher + icon**
- **Makefile support** (`make install`, `make uninstall`, `make build`)
- **Man page support** (`man amlogic-firmware-tool`)

---

## 📘 Documentation

| Section | Description |
|--------|-------------|
| 📥 [Installation & Usage](docs/installation_and_usage.md) | How to install and use the burn‑card tool |
| 🛠️ [Troubleshooting](docs/troubleshooting.md) | Common issues and solutions |

---

## 📦 Dependencies
The tool requires the following system utilities:

- `python3`
- `xxd`
- `gunzip`
- `losetup`
- `mount`

The tool automatically builds or installs missing components when possible.

---

## 📁 Directory Structure

```text
aml-burn-card-linux/
├── amlogic_firmware_tool.sh
├── unpack_amlogic_outer.py
├── install.sh
├── uninstall.sh
├── Makefile
├── amlogic.png
├── tools/
│   ├── simg2img
│   ├── verify_magic.sh
│   └── android-simg2img/
├── docs/
│   ├── installation_and_usage.txt
│   ├── troubleshooting.md
│   ├── architecture.md
│   └── faq.md
└── man/
    └── amlogic-firmware-tool.1
```
---

## 📜 License
This project is licensed under the **MIT License**.  
See the `LICENSE` file for details.

---
