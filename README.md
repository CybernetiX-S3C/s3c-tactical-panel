# S3C Tactical Panel
<p align="center">
  <img src="https://github.com/CybernetiX-S3C/s3c-tactical-panel/blob/main/logo.png?raw=true" width="400" alt="CybernetiX S3C Tactical Logo">
</p>

[![Release: v4.0-Aether](https://img.shields.io/badge/release-v4.0--Aether-brightgreen?style=flat-square)](https://github.com/CybernetiX-S3C/s3c-tactical-panel/releases/tag/v4.0-Aether)
[![License: MIT](https://img.shields.io/badge/license-MIT-brightgreen)](LICENSE)
[![Shell](https://img.shields.io/badge/language-Bash-blue)](https://www.gnu.org/software/bash/)
[![Version](https://img.shields.io/badge/version-4.0--Aether-critical)](#)
[![Built By](https://img.shields.io/badge/built--by-CybernetiX--S3C-purple)](https://github.com/CybernetiX-S3C)

```

╔═════════════════════════════════════════╗
║        S3C TACTICAL PANEL v4.0          ║
╚═════════════════════════════════════════╝

**Author:** John Poli Modica (CybernetiX S3C)
**GitHub:** [CybernetiX-S3C](https://github.com/CybernetiX-S3C)
**Version:** 4.0 (Codename: Aether)
**License:** MIT

````

---

## 📌 Overview

The **S3C Tactical Panel** is a robust, shell-based framework engineered for advanced wireless repeater management. Tailored for systems administrators, penetration testers, and network engineers, this tool provides full lifecycle control over hotspot deployment, diagnostics, session configuration, and restoration — all through an interactive voice-guided interface.

Every module is designed with reliability, auditability, and tactical efficiency in mind, making it ideal for both live field deployment and controlled lab environments. From zero-config repeater spins to graceful shutdowns and teardown protocols, S3C Tactical Panel offers precise oversight of repeater behavior and network posture.

Built natively in Bash, and leveraging common system tools like `dnsmasq`, `hostapd`, and `iptables`, it requires no dependencies beyond the base operating system and `flite` for voice interactivity.

This panel is designed with extensibility in mind, featuring **seamless integration with `CyberX ReconX`**. While `CyberX ReconX` is a powerful standalone diagnostic and recovery suite, its capabilities are directly accessible and integrated into the S3C Tactical Panel, providing a comprehensive solution for both repeater management and in-depth wireless troubleshooting.

---

## 🧠 Features

- 🎙 **Voice-Guided Interaction**
  Use of `flite` delivers real-time verbal feedback for operational clarity.

- 🧬 **Modular Hotspot Configuration**
  Save, load, and restore repeater session profiles with `.conf` files stored in a persistent directory.

- 🚨 **Instant Repeater Reset with Comprehensive Pre-Flight Network Purge**
  Execute full environment resets via `s3c-repeater-init.sh`, now including a complete NetworkManager restart and a comprehensive `iptables` and `ip6tables` flush (clearing all rules, chains, and tables including NAT, RAW, and MANGLE) *before* applying new configurations. This ensures a clean slate for NAT, DHCP, WPA2 provisioning, and interface setup, preventing lingering conflicts and guaranteeing optimal repeater functionality.

- 🔬 **Enhanced Network Diagnostics**
  Built-in pings, service status checks, and comprehensive IP address verification provide swift health assessments and service activation validation.

- 🧠 **Connected Client Monitoring**
  Displays ARP cache and active clients for real-time network visibility.

- 📜 **Log Viewing and Capture with Focused Auto-Cleanup**
  Pull logs directly from `/var/log/s3c-repeater.log` for troubleshooting or auditing. Features enhanced log truncation and journal vacuuming for system hygiene. The background auto-cleanup daemon now specifically focuses on aggressive log purification (truncating common active logs and vacuuming systemd journal) every 4 hours.

- 🔄 **Default Network Restoration**
  Returns wireless interfaces to `managed` mode using `nmcli` and cleans associated configurations, restoring factory-like behavior.

- 🧹 **Graceful Shutdown & Advanced System Purge**
  Terminates repeater services, flushes configurations, and performs aggressive log purification (truncating logs, vacuuming journal) with voice confirmation. Also stops the auto-cleanup daemon.

- 🛡️ **Systemd & IPTables Native**
  Handles service restarts and robust firewall rules without external libraries, including comprehensive flushing and default policy resets.

- 🛰 **CyberX ReconX Integration**
  Launch `CyberX ReconX` directly from the control panel. This integration provides seamless access to its advanced wireless diagnostics, driver management, MAC manipulation, and reconnaissance capabilities. **`CyberX ReconX` is a powerful standalone tool, available as a separate repository [here](https://github.com/CybernetiX-S3C/CyberX-ReconX), but is deeply integrated into the S3C Tactical Panel for enhanced functionality.**

- ⚙️ **MIT Licensed & Expandable**
  Open-source, extensible, and designed to be forked, embedded, or integrated.

---

## 🚀 Getting Started

Clone the repository and run the deploy script to install modules and register the command alias:

```bash
git clone [https://github.com/CybernetiX-S3C/s3c-tactical-panel.git](https://github.com/CybernetiX-S3C/s3c-tactical-panel.git)
cd s3c-tactical-panel
chmod +x s3c-repeater-*.sh
sudo ./s3c-repeater-deploy.sh
```

Once deployed, use:

```bash
s3cctl
```

You will be greeted with a voice prompt and the full ASCII-art tactical interface.

**CyberX ReconX Integration:**
Optionally install CyberX ReconX automatically from within the control panel if not already present.
It will be cloned to `/opt/CyberReconX` and globally registered as `cyberx`. You can also manually clone and install it from its dedicated repository:
`git clone https://github.com/CybernetiX-S3C/CyberX-ReconX.git`

📁 Directory Structure

```
s3c-tactical-panel/
├── s3c-repeater-control.sh     # Interactive panel interface
├── s3c-repeater-init.sh        # Repeater initializer and configuration
├── s3c-repeater-deploy.sh      # Installer and setup utility
├── .gitignore                  # File exclusions
├── LICENSE                     # MIT license
├── README.md                   # Project documentation
└── logo.png                    # CybernetiX S3C brand logo for the README
```

🛠 Dependencies
Ensure these system packages are installed before deploying:

  - `flite` — voice engine
  - `dnsmasq` — DHCP and DNS handler
  - `hostapd` — wireless access point daemon
  - `iptables` — firewall and NAT routing
  - `net-tools` — legacy tools for interface status
  - `git` — (for CyberX integration) version control system
  - `network-manager` — CLI tool for network interface management (`nmcli`)

All dependencies are checked and optionally installed by the deployer script if missing.

✨ Example Workflow

1.  Run `s3cctl`
2.  Configure a session or restore a previous one
3.  Reset repeater to apply settings
4.  Run diagnostics and monitor clients
5.  View logs as needed
6.  Shutdown or restore interfaces with voice confirmation
7.  **Leverage CyberX ReconX for advanced wireless diagnostics and recovery if needed, directly from the panel.**

⚠️ Disclaimer
S3C Tactical Panel manipulates network interfaces and system services. Use in live environments with caution. Administrator privileges are required for most operations. Always test in isolated or virtualized conditions before rolling out to production networks.

✒️ License
Licensed under the MIT License. Open to modification, reuse, and redistribution with attribution. No warranty expressed or implied.

## 👥 Contributors

  - **John Poli Modica** – Creator, Architect, and Lead Developer
  - Powered by CybernetiX S3C
