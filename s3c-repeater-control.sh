#!/usr/bin/env bash

# === S3C REPEATER CONTROL PANEL v3.0 (Orion) ===
SCRIPT_VERSION="v3.0 (Orion)"
LOGFILE="/var/log/s3c-repeater.log"
RESET_SCRIPT="/usr/local/bin/s3c-repeater-init"
SESSION_DIR="$HOME/.s3c/sessions"
SESSION_FILE="/tmp/s3c-session.conf"
USER_CTX="${SUDO_USER:-$USER}"

# Voice prompt on launch
su -l "$USER_CTX" -c 'flite -voice rms -t "Repeater interface activated. Orion control panel online."'

# ASCII-art banner
cat << 'EOF'
███    ███  ██████  ██████      ██████  ██████  ███████ ██████
████  ████ ██    ██ ██    ██    ██    ██ ██    ██ ██      ██   ██
██ ████ ██ ██    ██ ██    ██    ██    ██ ██    ██ █████   ██████
██  ██  ██ ██    ██ ██    ██    ██    ██ ██    ██ ██      ██   ██
██      ██  ██████   ██████  ██  ██████   ██████  ███████ ██   ██
EOF

echo "🔥 S3C Tactical Control — Version ${SCRIPT_VERSION} 🚨"
echo "📅 $(date) — Interface ready" | tee -a "$LOGFILE"

# Menu
PS3="🧭 Choose an action: "
options=(
  "🧬 Configure Hotspot Session"
  "🚨 Reset Repeater"
  "🔬 Run Diagnostics"
  "🧠 Show Connected Clients"
  "📜 View Logs"
  "🧹 Shutdown Repeater"
  "🔄 Restore Default Network Settings"
  "🛑 Exit"
)

select opt in "${options[@]}"; do
  case "$opt" in

    "🧬 Configure Hotspot Session")
      mkdir -p "$SESSION_DIR"
      mapfile -t SAVED < <(ls "$SESSION_DIR"/*.conf 2>/dev/null)
      if (( ${#SAVED[@]} > 0 )); then
        echo "📂 Available saved sessions:"
        for i in "${!SAVED[@]}"; do
          printf "  %d) %s\n" "$((i+1))" "$(basename "${SAVED[i]}" .conf)"
        done
        printf "  %d) Create new session\n" "$(( ${#SAVED[@]} + 1 ))"
        read -rp "Select session [1-$(( ${#SAVED[@]} + 1 ))]: " choice
        if (( choice >= 1 && choice <= ${#SAVED[@]} )); then
          cp "${SAVED[choice-1]}" "$SESSION_FILE"
          source "$SESSION_FILE"
          echo "✅ Loaded session: $SSID on $HOTSPOT_IF ↔ $UPLINK_IF"
          su -l "$USER_CTX" -c 'flite -voice rms -t "Session restored. Ready for initialization."'
          break
        fi
      fi

      echo "🧬 Hotspot Configuration"
      read -rp "📶 Hotspot Interface (e.g., wlan0): " HOTSPOT_IF
      read -rp "🛰️ Uplink Interface (e.g., wlan1): " UPLINK_IF
      if [[ $HOTSPOT_IF == "$UPLINK_IF" ]]; then
        echo "❌ Interfaces must differ."
        su -l "$USER_CTX" -c 'flite -voice rms -t "Configuration failed. Interfaces must not match."'
        break
      fi
      read -rp "📡 Hotspot SSID: " SSID
      read -rp "🔐 WPA2 Passphrase (8+ chars, blank for open): " PASSPHRASE

      {
        echo "HOTSPOT_IF=$HOTSPOT_IF"
        echo "UPLINK_IF=$UPLINK_IF"
        echo "SSID=$SSID"
        echo "PASSPHRASE=$PASSPHRASE"
      } > "$SESSION_FILE"

      read -rp "🗃️ Save session under a name? (optional): " SESSION_NAME
      if [[ -n $SESSION_NAME ]]; then
        cp "$SESSION_FILE" "$SESSION_DIR/$SESSION_NAME.conf"
        echo "✅ Session saved as $SESSION_NAME"
        su -l "$USER_CTX" -c 'flite -voice rms -t "Session saved for future use."'
      else
        su -l "$USER_CTX" -c 'flite -voice rms -t "Session configured. Apply on init."'
      fi
      break
      ;;

    "🚨 Reset Repeater")
      echo "🔄 Executing full repeater reset…" | tee -a "$LOGFILE"
      if [[ -x $RESET_SCRIPT ]]; then
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
      if [[ -f $SESSION_FILE ]]; then
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
      break
      ;;

    "🔄 Restore Default Network Settings")
      echo "🔄 Restoring default network settings…" | tee -a "$LOGFILE"
      if [[ -f $SESSION_FILE ]]; then
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

