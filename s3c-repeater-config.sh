#!/usr/bin/env bash

# === S3C REPEATER CONFIGURATION SCRIPT v4.0 (Aether) ===
SCRIPT_VERSION="v4.0 (Aether)"
SESSION_DIR="$HOME/.s3c/sessions"
SESSION_FILE="/tmp/s3c-session.conf"
USER_CTX="${SUDO_USER:-$USER}"

# This script will handle the creation, validation, and loading of session configurations.

validate_config() {
  local config_file="$1"
  source "$config_file"

  if [[ -z "$HOTSPOT_IF" || -z "$UPLINK_IF" || -z "$SSID" ]]; then
    echo "❌ Invalid configuration: Missing required fields."
    return 1
  fi

  if [[ "$HOTSPOT_IF" == "$UPLINK_IF" ]]; then
    echo "❌ Invalid configuration: Interfaces must differ."
    return 1
  fi

  if [[ -n "$PASSPHRASE" && ${#PASSPHRASE} -lt 8 ]]; then
    echo "❌ Invalid configuration: Passphrase must be at least 8 characters."
    return 1
  fi

  return 0
}

load_config() {
  local config_file="$1"
  if ! validate_config "$config_file"; then
    return 1
  fi
  cp "$config_file" "$SESSION_FILE"
  source "$SESSION_FILE"
  echo "✅ Loaded session: $SSID on $HOTSPOT_IF ↔ $UPLINK_IF"
  su -l "$USER_CTX" -c 'flite -voice rms -t "Session restored. Ready for initialization."'
}

create_new_session() {
  echo "🧬 Hotspot Configuration"
  read -rp "📶 Hotspot Interface (e.g., wlan0): " HOTSPOT_IF
  read -rp "🛰️ Uplink Interface (e.g., wlan1): " UPLINK_IF
  if [[ "$HOTSPOT_IF" == "$UPLINK_IF" ]]; then
    echo "❌ Interfaces must differ."
    su -l "$USER_CTX" -c 'flite -voice rms -t "Configuration failed. Interfaces must not match."'
    return 1
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
  if [[ -n "$SESSION_NAME" ]]; then
    mkdir -p "$SESSION_DIR"
    cp "$SESSION_FILE" "$SESSION_DIR/$SESSION_NAME.conf"
    echo "✅ Session saved as $SESSION_NAME"
    su -l "$USER_CTX" -c 'flite -voice rms -t "Session saved for future use."'
  else
    su -l "$USER_CTX" -c 'flite -voice rms -t "Session configured. Apply on init."'
  fi
}

list_sessions() {
  mkdir -p "$SESSION_DIR"
  mapfile -t SAVED < <(ls "$SESSION_DIR"/*.conf 2>/dev/null)
  if (( ${#SAVED[@]} > 0 )); then
    echo "📂 Available saved sessions:"
    for i in "${!SAVED[@]}"; do
      printf "  %d) %s\n" "$((i+1))" "$(basename "${SAVED[i]}" .conf)"
    done
  else
    echo "No saved sessions found."
  fi
}
