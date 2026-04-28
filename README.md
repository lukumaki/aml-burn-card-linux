## Amlogic Burn Card Linux Tool

<p align="center">
<!-- Badges -->
  <img src="https://img.shields.io/badge/version-1.0.0-blue.svg" alt="Version">
  <img src="https://img.shields.io/badge/license-MIT-green.svg" alt="License">
  <img src="https://img.shields.io/badge/Linux%20Mint-supported-success.svg" alt="Linux Mint Support">
  <img src="https://img.shields.io/badge/Amlogic-S905X3%20%7C%20S922X%20%7C%20S905X2-orange.svg" alt="Amlogic Support">
  <img src="https://img.shields.io/badge/Architecture-x86__64-lightgrey.svg" alt="Architecture">
</p>

---

## A complete Linux Mint utility for:

- unpacking Amlogic firmware `.img` files  
- extracting burn‑card bootloader files  
- converting Android sparse images  
- creating bootable Amlogic SD cards  
- restoring SD cards to normal  
- running as a real Linux application  

Supports all modern Amlogic devices (S905X, S905X2, S905X3, S922X, etc).


## ✨ Features

- **Full firmware unpacker** (outer + partitions)  
- **Automatic detection** of `aml_sdc_burn.UBOOT` and `aml_sdc_burn.ini`  
- **Sparse image detection** + optional conversion  
- **Interactive device selection**  
- **Normal / Dry‑run / Verify‑only modes**  
- **Logging**  
- **Desktop launcher**  
- **Installable as a real Linux Mint application**  
- **Restore SD card to normal mode**  


## 📦 Dependencies

- **Install required tools:**
<pre>sudo apt install -y python3 parted dosfstools android-sdk-libsparse-utils gnome-terminal</pre>


## 🛠 Installation

- **Clone the repository:**
<pre>git clone https://github.com/lukumaki/aml-burn-card-linux.git
cd aml-burn-card-linux</pre>
- **Run the installer:**
<pre>chmod +x install.sh
sudo ./install.sh</pre>
- **Launch the app:**
<pre>amlogic-firmware-tool</pre>
Or from the Mint Menu → Utilities → Amlogic Firmware Tool


## 🚀 Usage

Place your firmware `.img` files in any directory and run:
<pre>amlogic-firmware-tool</pre>
The tool will:
- Ask which firmware to unpack
- Extract all burn files
- Ask which SD device to use
- Create a bootable Amlogic SD card

To restore an SD card:
<pre>amlogic-firmware-tool restore</pre>


## 📄 License

MIT License.
