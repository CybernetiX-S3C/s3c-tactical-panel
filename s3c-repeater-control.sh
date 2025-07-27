#!/usr/bin/env bash

# === S3C REPEATER CONTROL PANEL v4.0 (Aether) ===
SCRIPT_VERSION="v4.0 (Aether)" # Updated to Aether
LOGFILE="/var/log/s3c-repeater.log"
RESET_SCRIPT="/usr/local/bin/s3c-repeater-init"
SESSION_DIR="$HOME/.s3c/sessions"
SESSION_FILE="/tmp/s3c-session.conf"
CONFIG_SCRIPT="/usr/local/bin/s3c-repeater-config"
USER_CTX="${SUDO_USER:-$USER}"

# Source the config script
source "$CONFIG_SCRIPT"

# Voice prompt on launch
su -l "$USER_CTX" -c 'flite -voice rms -t "Repeater interface activated. Aether control panel online."'

# ASCII-art banner
cat << 'EOF'
███    ███  ██████  ██████      ██████  ██████  ███████ ██████
████  ████ ██     ██ ██     ██    ██     ██ ██     ██ ██       ██   ██
██ ████ ██ ██   ██ ██   ██    ██   ██ ██   ██ █████   ██████
██  ██  ██ ██   ██ ██   ██    ██   ██ ██   ██ ██       ██    ██
██      ██  ██████   ██████  ██  ██████   ██████  ███████ ██   ██
EOF

echo "🔥 S3C Tactical Control — Version ${SCRIPT_VERSION} 🚨"
echo "📅 $(date) — Interface ready" | tee -a "$LOGFILE"

# Menu
PS3="🧭 Choose an action: "
options=(
  "🧬 Configure Hotspot Session"
  "🗑️ Cleanse Saved Sessions"
  "🚨 Reset Repeater"
  "🔬 Run Diagnostics"
  "🧠 Show Connected Clients"
  "📜 View Logs"
  "🧹 Shutdown Repeater"
  "🔄 Restore Default Network Settings"
  "🛰️ Launch CyberX ReconX Suite"
  "🛑 Exit"
)

select opt in "${options[@]}"; do
  case "$opt" in

    "🧬 Configure Hotspot Session")
      list_sessions
      read -rp "Select session or create new [1-n, c]: " choice
      if [[ "$choice" == "c" ]]; then
        create_new_session
      else
        mapfile -t SAVED < <(ls "$SESSION_DIR"/*.conf 2>/dev/null)
        if (( choice >= 1 && choice <= ${#SAVED[@]} )); then
          load_config "${SAVED[choice-1]}"
        else
          echo "Invalid selection."
        fi
      fi
      break
      ;;

    "🗑️ Cleanse Saved Sessions")
      echo "🗑️ Cleansing saved sessions…" | tee -a "$LOGFILE"
      mapfile -t SAVED_TO_CLEAN < <(ls "$SESSION_DIR"/*.conf 2>/dev/null)
      if (( ${#SAVED_TO_CLEAN[@]} > 0 )); then
        echo "📂 Available sessions to delete:"
        for i in "${!SAVED_TO_CLEAN[@]}"; do
          printf "  %d) %s\n" "$((i+1))" "$(basename "${SAVED_TO_CLEAN[i]}" .conf)"
        done
        printf "  %d) ALL SESSIONS\n" "$(( ${#SAVED_TO_CLEAN[@]} + 1 ))"
        read -rp "Select session(s) to delete (e.g., 1 3 or $(( ${#SAVED_TO_CLEAN[@]} + 1 )) for ALL): " delete_choices

        # Split choices into an array
        IFS=' ' read -r -a choices_array <<< "$delete_choices"

        for choice in "${choices_array[@]}"; do
          if [[ "$choice" -ge 1 && "$choice" -le "${#SAVED_TO_CLEAN[@]}" ]]; then
            TARGET_FILE="${SAVED_TO_CLEAN[choice-1]}"
            rm -f "$TARGET_FILE"
            echo "✅ Removed session: $(basename "$TARGET_FILE" .conf)" | tee -a "$LOGFILE"
          elif [[ "$choice" -eq $(( ${#SAVED_TO_CLEAN[@]} + 1 )) ]]; then
            read -rp "Are you sure you want to delete ALL saved sessions? (y/N): " confirm_all
            if [[ "$confirm_all" =~ ^[Yy]$ ]]; then
              rm -f "$SESSION_DIR"/*.conf
              echo "✅ ALL saved sessions removed." | tee -a "$LOGFILE"
              break # Exit the loop after deleting all
            else
              echo "❌ Deletion of all sessions cancelled." | tee -a "$LOGFILE"
            fi
          else
            echo "⚠️ Invalid selection: $choice" | tee -a "$LOGFILE"
          fi
        done
        su -l "$USER_CTX" -c 'flite -voice rms -t "Session cleansing complete."'
      else
        echo "❌ No saved sessions to cleanse." | tee -a "$LOGFILE"
        su -l "$USER_CTX" -c 'flite -voice rms -t "No sessions to cleanse."'
      fi
      break
      ;;

    "🚨 Reset Repeater")
      echo "🔄 Executing full repeater reset…" | tee -a "$LOGFILE"
      if [[ -x "$RESET_SCRIPT" ]]; then
        sudo "$RESET_SCRIPT"
      else
        echo "⚠️ Reset script not found." | tee -a "$LOGFILE"
        su -l "$USER_CTX" -c 'flite -voice rms -t "Reset failed. Init module missing."'
      fi
      break
      ;;

    "🔬 Run Diagnostics")
      echo "🔬 Interface IPs:" | tee -a "$LOGFILE"
      ip addr show | grep -w inet | tee -a "$LOGFILE"
      echo "📡 Service status:" | tee -a "$LOGFILE"
      systemctl is-active dnsmasq && echo "✅ dnsmasq active." | tee -a "$LOGFILE"
      systemctl is-active hostapd && echo "✅ hostapd active." | tee -a "$LOGFILE"
      echo "🌐 Internet test:" | tee -a "$LOGFILE"
      if ping -c2 -W2 8.8.8.8 &> /dev/null; then
        echo "✅ Internet reachable." | tee -a "$LOGFILE"
        su -l "$USER_CTX" -c 'flite -voice rms -t "Internet connectivity confirmed."'
      else
        echo "❌ Internet unreachable." | tee -a "$LOGFILE"
        su -l "$USER_CTX" -c 'flite -voice rms -t "Internet connectivity failed."'
      fi
      break
      ;;

    "🧠 Show Connected Clients")
      echo "🧠 ARP Cache:" | tee -a "$LOGFILE"
      arp -n | grep -v incomplete | tee -a "$LOGFILE"
      su -l "$USER_CTX" -c 'flite -voice rms -t "Connected clients listed."'
      break
      ;;

    "📜 View Logs")
      echo "📜 Recent Repeater Log:" | tee -a "$LOGFILE"
      tail -n30 "$LOGFILE"
      su -l "$USER_CTX" -c 'flite -voice rms -t "Log display complete."'
      break
      ;;

    "🧹 Shutdown Repeater")
      echo "🧹 Shutting down repeater…" | tee -a "$LOGFILE"
      if [[ -f "$SESSION_FILE" ]]; then
        source "$SESSION_FILE"
        sudo systemctl stop dnsmasq hostapd
        sudo ip addr flush dev "$HOTSPOT_IF"
        sudo ip link set "$HOTSPOT_IF" down
        sudo ip addr flush dev "$UPLINK_IF"
        sudo ip link set "$UPLINK_IF" down
        sudo iptables -F
        sudo iptables -t nat -F
        sudo iptables -X
        echo 0 | sudo tee /proc/sys/net/ipv4/ip_forward
        su -l "$USER_CTX" -c 'flite -voice rms -t "Repeater shut down. Interfaces disabled."'
      else
        echo "❌ No session to shut down." | tee -a "$LOGFILE"
        su -l "$USER_CTX" -c 'flite -voice rms -t "Shutdown failed. No session found."'
      fi

      # === Stop Auto-Cleanup Daemon ===
      if [[ -f "/tmp/s3c_auto_cleanup.pid" ]]; then
          CLEANUP_PID=$(cat "/tmp/s3c_auto_cleanup.pid")
          echo "🛑 Stopping auto-cleanup daemon (PID: $CLEANUP_PID)..." | tee -a "$LOGFILE"
          sudo kill "$CLEANUP_PID" 2>/dev/null || true
          sudo rm -f "/tmp/s3c_auto_cleanup.pid"
          echo "✅ Auto-cleanup daemon stopped." | tee -a "$LOGFILE"
      fi
      # ================================

      # === S3C LOG PURIFIER INTEGRATION (Shutdown System Cleanup) ===
      echo "🧹 Performing shutdown system cleanup..." | tee -a "$LOGFILE"

      # Truncate Large Active System Logs
      echo "  Truncating common active log files..." | tee -a "$LOGFILE"
      sudo truncate -s 0 /var/log/syslog
      sudo truncate -s 0 /var/log/kern.log
      sudo truncate -s 0 /var/log/auth.log
      sudo truncate -s 0 /var/log/daemon.log
      sudo truncate -s 0 /var/log/debug.log
      sudo truncate -s 0 /var/log/messages
      sudo truncate -s 0 /var/log/boot.log 2>/dev/null || true
      sudo truncate -s 0 /var/log/alternatives.log 2>/dev/null || true
      sudo truncate -s 0 /var/log/s3c-repeater.log # Your S3C log file

      # Vacuum System Journal Logs Aggressively
      echo "  Aggressively vacuuming systemd journal logs..." | tee -a "$LOGFILE"
      sudo journalctl --vacuum-size=50M
      sudo journalctl --vacuum-time=12h
      echo "✅ Shutdown cleanup complete." | tee -a "$LOGFILE"
      # ===============================================

      break
      ;;

    "🔄 Restore Default Network Settings")
      echo "🔄 Restoring default network settings…" | tee -a "$LOGFILE"
      if [[ -f "$SESSION_FILE" ]]; then
        source "$SESSION_FILE"
        sudo pkill -f "wpa_supplicant.*${HOTSPOT_IF}" &> /dev/null || true
        sudo nmcli device set "$HOTSPOT_IF" managed yes &> /dev/null || true
        sudo nmcli device connect "$HOTSPOT_IF" &> /dev/null || true
        sudo ip link set "$HOTSPOT_IF" up
        sudo ip addr flush dev "$HOTSPOT_IF"
        sudo ip addr flush dev "$UPLINK_IF"
        sudo ip link set "$UPLINK_IF" up
        echo "✅ Default network settings applied." | tee -a "$LOGFILE"
        su -l "$USER_CTX" -c 'flite -voice rms -t "Default network settings restored."'
      else
        echo "❌ No session available to restore from." | tee -a "$LOGFILE"
        su -l "$USER_CTX" -c 'flite -voice rms -t "Session not found. Restore skipped."'
      fi

      # === Stop Auto-Cleanup Daemon ===
      if [[ -f "/tmp/s3c_auto_cleanup.pid" ]]; then
          CLEANUP_PID=$(cat "/tmp/s3c_auto_cleanup.pid")
          echo "🛑 Stopping auto-cleanup daemon (PID: $CLEANUP_PID)..." | tee -a "$LOGFILE"
          sudo kill "$CLEANUP_PID" 2>/dev/null || true
          sudo rm -f "/tmp/s3c_auto_cleanup.pid"
          echo "✅ Auto-cleanup daemon stopped." | tee -a "$LOGFILE"
      fi
      # ================================

      # === S3C LOG PURIFIER INTEGRATION (Default Network Settings Restoration Cleanup) ===
      echo "🧹 Performing default network settings restoration cleanup..." | tee -a "$LOGFILE"

      # Truncate Large Active System Logs
      echo "  Truncating common active log files..." | tee -a "$LOGFILE"
      sudo truncate -s 0 /var/log/syslog
      sudo truncate -s 0 /var/log/kern.log
      sudo truncate -s 0 /var/log/auth.log
      sudo truncate -s 0 /var/log/daemon.log
      sudo truncate -s 0 /var/log/debug.log
      sudo truncate -s 0 /var/log/messages
      sudo truncate -s 0 /var/log/boot.log 2>/dev/null || true
      sudo truncate -s 0 /var/log/alternatives.log 2>/dev/null || true
      sudo truncate -s 0 /var/log/s3c-repeater.log # Your S3C log file

      # Vacuum System Journal Logs Aggressively
      echo "  Aggressively vacuuming systemd journal logs..." | tee -a "$LOGFILE"
      sudo journalctl --vacuum-size=50M
      sudo journalctl --vacuum-time=12h
      echo "✅ Default network settings restoration cleanup complete." | tee -a "$LOGFILE"
      # =======================================================

      break
      ;;

    "🛰️ Launch CyberX ReconX Suite")
      if command -v cyberx &>/dev/null; then
        echo "🚀 Launching CyberX ReconX..."
        su -l "$USER_CTX" -c 'flite -voice rms -t "Cyber X Recon suite engaging."'
        sudo cyberx
      else
        echo "🔧 CyberX not found. Installing..."
        git clone https://github.com/CybernetiX-S3C/CyberX-ReconX.git /opt/CyberReconX
        bash /opt/CyberReconX/install.sh
      fi
      break
      ;;

    "🛑 Exit")
      echo "🛑 Exiting control panel." | tee -a "$LOGFILE"
      su -l "$USER_CTX" -c 'flite -voice rms -t "Control panel shut down."'
      exit 0
      ;;

    *)
      echo "💥 Invalid choice. Try again." | tee -a "$LOGFILE"
      su -l "$USER_CTX" -c 'flite -voice rms -t "Invalid selection. Awaiting input."'
      ;;
  esac
done
