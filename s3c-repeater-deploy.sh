#!/usr/bin/env bash

# === S3C REPEATER DEPLOYMENT SCRIPT v4.0 (Aether) ===
DEPLOY_VERSION="v4.0 (Aether)"
CONTROL_SRC="./s3c-repeater-control.sh" # Assumes control script is in the same directory
INIT_SRC="./s3c-repeater-init.sh"      # Assumes init script is in the same directory
CONFIG_SRC="./s3c-repeater-config.sh"    # Assumes config script is in the same directory
BIN_DIR="/usr/local/bin"
INSTALL_LOG="/var/log/s3c-deploy.log"
LOGFILE="/var/log/s3c-repeater.log" # This log will be managed by init/control scripts
ALIAS_LINE="alias s3cctl='sudo ${BIN_DIR}/s3c-repeater-control'"
SESSION_DIR="$HOME/.s3c/sessions"

# ASCII-art banner for deployment
cat << 'EOF'
██████  ███████ ██████   ██████   ██████   ██████
██   ██ ██      ██   ██ ██    ██ ██    ██ ██    ██
██████  █████   ██████  ██    ██ ██    ██ ██    ██
██   ██ ██      ██   ██ ██    ██ ██    ██ ██    ██
██   ██ ███████ ██   ██  ██████   ██████   ██████
EOF

echo "🚀 S3C Repeater Deployment - Version ${DEPLOY_VERSION} 🚀" | tee "$INSTALL_LOG"
echo "📅 $(date) — Commencing installation ritual for Aether." | tee -a "$INSTALL_LOG"

# 1. Cache sudo credentials
echo "🔑 Requesting sudo privileges..." | tee -a "$INSTALL_LOG"
sudo -v | tee -a "$INSTALL_LOG"
echo "✅ Sudo privileges acquired." | tee -a "$INSTALL_LOG"

# 2. Determine invoking user
USER_CTX="${SUDO_USER:-$USER}"
USER_HOME="$(eval echo "~$USER_CTX")"
echo "👤 Deploying for user: $USER_CTX (Home: $USER_HOME)" | tee -a "$INSTALL_LOG"

# 3. Voice-enabled start
su -l "$USER_CTX" -c 'flite -voice rms -t "Repeater deployment engaged. Aether version four point zero active."'

# 4. Check & install required packages
REQUIRED_PKGS=(flite net-tools dnsmasq hostapd iptables git network-manager) # Added git and network-manager
MISSING=()
echo "📦 Checking and installing essential components..." | tee -a "$INSTALL_LOG"
for pkg in "${REQUIRED_PKGS[@]}"; do
  if ! dpkg -s "$pkg" &>/dev/null; then
    MISSING+=("$pkg")
  else
    echo "✅ $pkg already installed." | tee -a "$INSTALL_LOG"
  fi
done

if [ "${#MISSING[@]}" -gt 0 ]; then
  echo "📦 Installing missing packages: ${MISSING[*]}" | tee -a "$INSTALL_LOG"
  sudo apt update -y | tee -a "$INSTALL_LOG"
  sudo apt install -y "${MISSING[@]}" | tee -a "$INSTALL_LOG"
  if [ $? -ne 0 ]; then
      echo "❌ Failed to install required packages. Aborting deployment." | tee -a "$INSTALL_LOG"
      su -l "$USER_CTX" -c 'flite -voice rms -t "Package installation failed. Deployment aborted."'
      exit 1
  fi
  for pkg in "${MISSING[@]}"; do
    su -l "$USER_CTX" -c "flite -voice rms -t '$pkg installed successfully.'"
  done
else
  echo "✅ All essential components verified as installed." | tee -a "$INSTALL_LOG"
fi

# --- 5. Create Necessary Directories and Log File ---
echo "📂 Creating essential directories and log file..." | tee -a "$INSTALL_LOG"
mkdir -p "$SESSION_DIR" | tee -a "$INSTALL_LOG"
sudo touch "$LOGFILE" | tee -a "$INSTALL_LOG" # Ensure log file exists
sudo chown "$USER_CTX":"$USER_CTX" "$LOGFILE" | tee -a "$INSTALL_LOG" # Set user ownership
sudo chmod 666 "$LOGFILE" | tee -a "$INSTALL_LOG" # Set permissions for user read/write and others read/write
echo "✅ Directories and log file prepared." | tee -a "$INSTALL_LOG"

# --- 6. Validate Source Scripts ---
echo "🔎 Validating source scripts existence..." | tee -a "$INSTALL_LOG"
if [ ! -f "$CONTROL_SRC" ]; then
    echo "❌ Control script not found: $CONTROL_SRC. Aborting." | tee -a "$INSTALL_LOG"
    su -l "$USER_CTX" -c 'flite -voice rms -t "Control script missing. Deployment aborted."'
    exit 1
fi
if [ ! -f "$INIT_SRC" ]; then
    echo "❌ Init script not found: $INIT_SRC. Aborting." | tee -a "$INSTALL_LOG"
    su -l "$USER_CTX" -c 'flite -voice rms -t "Initialization script missing. Deployment aborted."'
    exit 1
fi
if [ ! -f "$CONFIG_SRC" ]; then
    echo "❌ Config script not found: $CONFIG_SRC. Aborting." | tee -a "$INSTALL_LOG"
    su -l "$USER_CTX" -c 'flite -voice rms -t "Configuration script missing. Deployment aborted."'
    exit 1
fi
echo "✅ Source scripts found." | tee -a "$INSTALL_LOG"

# --- 7. Copy scripts & enforce ownership and permissions ---
echo "🛠️ Installing control & init modules, setting ownership and permissions…" | tee -a "$INSTALL_LOG"
sudo cp "$CONTROL_SRC" "$BIN_DIR/s3c-repeater-control" | tee -a "$INSTALL_LOG"
sudo cp "$INIT_SRC" "$BIN_DIR/s3c-repeater-init" | tee -a "$INSTALL_LOG"
sudo cp "$CONFIG_SRC" "$BIN_DIR/s3c-repeater-config" | tee -a "$INSTALL_LOG"

sudo chown root:root "$BIN_DIR/s3c-repeater-control" "$BIN_DIR/s3c-repeater-init" "$BIN_DIR/s3c-repeater-config" | tee -a "$INSTALL_LOG"
sudo chmod 755 "$BIN_DIR/s3c-repeater-control" "$BIN_DIR/s3c-repeater-init" "$BIN_DIR/s3c-repeater-config" | tee -a "$INSTALL_LOG"

su -l "$USER_CTX" -c 'flite -voice rms -t "Modules deployed. Ownership and permissions set."'
echo "✅ Core repeater scripts deployed and secured." | tee -a "$INSTALL_LOG"

# --- 8. Register alias in shell RC file ---
echo "🔗 Creating 's3cctl' alias for easy access..." | tee -a "$INSTALL_LOG"
ALIAS_LINE="alias s3cctl='sudo ${BIN_DIR}/s3c-repeater-control'"

# Add to .bashrc for current user
if [ -f "$USER_HOME/.bashrc" ]; then
    if ! grep -Fxq "$ALIAS_LINE" "$USER_HOME/.bashrc"; then
        echo "$ALIAS_LINE" >> "$USER_HOME/.bashrc"
        echo "🪄 Alias added to $USER_HOME/.bashrc" | tee -a "$INSTALL_LOG"
    else
        echo "🪄 Alias already present in $USER_HOME/.bashrc" | tee -a "$INSTALL_LOG"
    fi
fi

# Add to .zshrc for current user (if zsh is used)
if [ -f "$USER_HOME/.zshrc" ]; then
    if ! grep -Fxq "$ALIAS_LINE" "$USER_HOME/.zshrc"; then
        echo "$ALIAS_LINE" >> "$USER_HOME/.zshrc"
        echo "🪄 Alias added to $USER_HOME/.zshrc" | tee -a "$INSTALL_LOG"
    else
        echo "🪄 Alias already present in $USER_HOME/.zshrc" | tee -a "$INSTALL_LOG"
    fi
fi

# Also add to /etc/bash.bashrc for all users for broader access
if ! grep -Fxq "$ALIAS_LINE" "/etc/bash.bashrc"; then
    echo "$ALIAS_LINE" | sudo tee -a /etc/bash.bashrc > /dev/null
    echo "🪄 Alias added to /etc/bash.bashrc for all users." | tee -a "$INSTALL_LOG"
else
    echo "🪄 Alias already present in /etc/bash.bashrc" | tee -a "$INSTALL_LOG"
fi

# Source the relevant RC file for immediate effect in the current shell
# Note: This only works if the script is sourced, not executed directly.
# For direct execution, user will still need to open a new terminal or source manually.
su -l "$USER_CTX" -c "source '$USER_HOME/.bashrc' 2>/dev/null || true"
su -l "$USER_CTX" -c "source '$USER_HOME/.zshrc' 2>/dev/null || true" # For zsh users

su -l "$USER_CTX" -c 'flite -voice rms -t "Alias s three c control registered."'
echo "✅ 's3cctl' alias created. Please open a new terminal or run 'source ~/.bashrc' (or .zshrc) for immediate effect." | tee -a "$INSTALL_LOG"

# --- 9. Final confirmation ---
echo "✅ Deployment complete. You are now ready to command the S3C Repeater v${DEPLOY_VERSION}." | tee -a "$INSTALL_LOG"
echo "To start the control panel, run: s3cctl" | tee -a "$INSTALL_LOG"
echo "Deployment ritual finished. Aether's power awaits your command." | tee -a "$INSTALL_LOG"

# Final voice prompt
su -l "$USER_CTX" -c 'flite -voice rms -t "Deployment complete. Aether is online."'
