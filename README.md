# S3C Tactical Panel
<p align="center">
  <img src="logo.png" width="400" alt="CybernetiX S3C Tactical Logo">
</p>
[![Release: v3.0-Orion](https://img.shields.io/badge/release-v3.0--Orion-brightgreen?style=flat-square)](https://github.com/CybernetiX-S3C/s3c-tactical-panel/releases/tag/v3.0-Orion)
[![License: MIT](https://img.shields.io/badge/license-MIT-brightgreen)](LICENSE)
[![Shell](https://img.shields.io/badge/language-Bash-blue)](https://www.gnu.org/software/bash/)
[![Version](https://img.shields.io/badge/version-3.0--Orion-critical)](#)
[![Built By](https://img.shields.io/badge/built--by-CybernetiX--S3C-purple)](https://github.com/CybernetiX-S3C)
```
╔═════════════════════════════════════════╗
║         S3C TACTICAL PANEL v3.0         ║
╚═════════════════════════════════════════╝

**Author:** John Poli Modica (CybernetiX S3C)  
**GitHub:** [CybernetiX-S3C](https://github.com/CybernetiX-S3C)  
**Version:** 3.0 (Codename: Orion)  
**License:** MIT
```

---

## 📌 Overview

The **S3C Tactical Panel** is a robust, shell-based framework engineered for advanced wireless repeater management. Tailored for systems administrators, penetration testers, and network engineers, this tool provides full lifecycle control over hotspot deployment, diagnostics, session configuration, and restoration — all through an interactive voice-guided interface.

Every module is designed with reliability, auditability, and tactical efficiency in mind, making it ideal for both live field deployment and controlled lab environments. From zero-config repeater spins to graceful shutdowns and teardown protocols, S3C Tactical Panel offers precise oversight of repeater behavior and network posture.

Built natively in Bash, and leveraging common system tools like `dnsmasq`, `hostapd`, and `iptables`, it requires no dependencies beyond the base operating system and `flite` for voice interactivity.

---

## 🧠 Features

- 🎙 **Voice-Guided Interaction**  
  Use of `flite` delivers real-time verbal feedback for operational clarity.

- 🧬 **Modular Hotspot Configuration**  
  Save, load, and restore repeater session profiles with `.conf` files stored in a persistent directory.

- 🚨 **Instant Repeater Reset**  
  Execute full environment resets via `s3c-repeater-init.sh`, complete with NAT, DHCP, WPA2 provisioning, and interface setup.

- 🔬 **Network Diagnostics**  
  Built-in pings, service status checks, and IP address verification provide quick health assessments.

- 🧠 **Connected Client Monitoring**  
  Displays ARP cache and active clients for realtime network visibility.

- 📜 **Log Viewing and Capture**  
  Pull logs directly from `/var/log/s3c-repeater.log` for troubleshooting or auditing.

- 🔄 **Default Network Restoration**  
  Returns wireless interfaces to managed mode using `nmcli`, restoring factory-like behavior.

- 🧹 **Graceful Shutdown Tools**  
  Terminates repeater services and flushes configurations with voice confirmation.

- 🛡️ **Systemd & IPTables Native**  
  Handles service restarts and firewall rules without external libraries.

- ⚙️ **MIT Licensed & Expandable**  
  Open-source, extensible, and designed to be forked, embedded, or integrated.

---

## 🚀 Getting Started

Clone the repository and run the deploy script to install modules and register the command alias:

```bash
git clone https://github.com/CybernetiX-S3C/s3c-tactical-panel.git
cd s3c-tactical-panel
chmod +x s3c-repeater-*.sh
sudo ./s3c-repeater-deploy.sh
```

Once deployed, use:
```
s3cctl
```
You will be greeted with a voice prompt and the full ASCII-art tactical interface.

📁 Directory Structure
```
s3c-tactical-panel/
├── s3c-repeater-control.sh     # Interactive panel interface
├── s3c-repeater-init.sh        # Repeater initializer and configuration
├── s3c-repeater-deploy.sh      # Installer and setup utility
├── .gitignore                  # File exclusions
├── LICENSE                     # MIT license
└── README.md                   # Project documentation
```

🛠 Dependencies
Ensure these system packages are installed before deploying:

flite — voice engine

dnsmasq — DHCP and DNS handler

hostapd — wireless access point daemon

iptables — firewall and NAT routing

net-tools — legacy tools for interface status

nmcli — (optional) NetworkManager CLI for restoration

All dependencies are checked and optionally installed by the deployer script if missing.

✨ Example Workflow
Run s3cctl

Configure a session or restore a previous one

Reset repeater to apply settings

Run diagnostics and monitor clients

View logs as needed

Shutdown or restore interfaces with voice confirmation

⚠️ Disclaimer
S3C Tactical Panel manipulates network interfaces and system services. Use in live environments with caution. Administrator privileges are required for most operations. Always test in isolated or virtualized conditions before rolling out to production networks.

✒️ License
Licensed under the MIT License. Open to modification, reuse, and redistribution with attribution. No warranty expressed or implied.

## 👥 Contributors

- **John Poli Modica** – Creator, Architect, and Lead Developer  
- Powered by CybernetiX S3C

