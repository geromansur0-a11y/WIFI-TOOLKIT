# 📡 WiFi Toolkit

> **Advanced yet portable Bash toolkit for authorized wireless penetration testing.**  
> Supports **WPA/WPA2 handshake capture + cracking**, **WPS (Reaver/PixieDust)**, and **WEP attacks**.

⚠️ **For educational and authorized use ONLY.** Unauthorized use is illegal.

---

## ✨ Features

- 🧭 **Portable**: No hardcoded paths — runs from any directory
- 🔍 **Auto-detects** wireless interface (`wlan0`, `wlp3s0`, etc.)
- 🛠️ **Modular attacks**:
  - WPA/WPA2: Capture handshake + crack with custom wordlist
  - WPS: Reaver + Pixie-Dust attack
  - WEP: IVs collection + key cracking
- 🎨 Color-coded output for readability
- 🗂️ Session-based logging (`/tmp/portable_session_...`)

---

## 🚀 Quick Start

### Prerequisites
- Linux (Kali, Parrot, Ubuntu, etc.)
- `aircrack-ng` suite (`aircrack-ng`, `aireplay-ng`, `airodump-ng`)
- `reaver` & `wash` (for WPS attacks)
- Wireless card supporting **monitor mode** and **packet injection**

### Install Dependencies (Debian/Ubuntu/Kali)
```bash
sudo apt update
sudo apt install aircrack-ng reaver

git clone https://github.com/geromansur0-a11y/WIFI-TOOLKIT.git
cd wifi-toolkit
chmod +x install.sh wifitoolkit.sh
sudo ./install.sh
sudo ./wifitoolkit.sh
