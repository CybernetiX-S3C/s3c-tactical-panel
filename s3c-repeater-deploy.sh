#!/usr/bin/env bash

# === S3C REPEATER DEPLOYER v3.0 (Orion) ===
SCRIPT_VERSION="v3.0 (Orion)"
CONTROL_SRC="./s3c-repeater-control.sh"
INIT_SRC="./s3c-repeater-init.sh"
BIN_DIR="/usr/local/bin"
LOGFILE="/var/log/s3c-repeater.log"
ALIAS_LINE="alias s3cctl='sudo /usr/local/bin/s3c-repeater-control'"
SESSION_DIR="$HOME/.s3c/sessions"

echo "🔧 Deploying S3C Repeater Suite — Version ${SCRIPT_VERSION}"

# 1. Cache sudo credentials
sudo -v

# 2. Determine invoking user
USER_CTX="${SUDO_USER:-$USER}"
USER_HOME="$(eval echo "~$USER_CTX")"

# 3. Voice-enabled start
su -l "$USER_CTX" -c 'flite -voice rms -t "Repeater deployment engaged. Orion version three point zero active."'

# 4. Check & install required packages
REQUIRED_PKGS=(flite net-tools dnsmasq hostapd iptables)
MISSING=()
for pkg in "${REQUIRED_PKGS[@]}"; do
  if ! dpkg -s "$pkg" &>/dev/null; then
    MISSING+=("$pkg")
  else
    echo "✅ $pkg already installed."
    su -l "$USER_CTX" -c "flite -voice rms -t '$pkg verified.'"
  fi
done

if [ "${#MISSING[@]}" -gt 0 ]; then
  echo "📦 Installing missing packages: ${MISSING[*]}"
  sudo apt update
  sudo apt install -y "${MISSING[@]}"
  for pkg in "${MISSING[@]}"; do
    su -l "$USER_CTX" -c "flite -voice rms -t '$pkg installed successfully.'"
  done
fi

# 5. Copy scripts & enforce ownership and permissions
echo "🛠️ Installing control & init modules, setting ownership and permissions…"
sudo bash -c "
  cp '$CONTROL_SRC' '$BIN_DIR/s3c-repeater-control'
  cp '$INIT_SRC'    '$BIN_DIR/s3c-repeater-init'
  chown root:root   '$BIN_DIR/s3c-repeater-control' '$BIN_DIR/s3c-repeater-init'
  chmod 755         '$BIN_DIR/s3c-repeater-control' '$BIN_DIR/s3c-repeater-init'
  mkdir -p '$SESSION_DIR'
  touch '$LOGFILE'
  chown '$USER_CTX':'$USER_CTX' '$LOGFILE'
  chmod 666         '$LOGFILE'
"
su -l "$USER_CTX" -c 'flite -voice rms -t "Modules deployed. Ownership and permissions set."'

# 6. Register alias in shell RC file
if [ -f "$USER_HOME/.bashrc" ]; then
  RC_FILE="$USER_HOME/.bashrc"
elif [ -f "$USER_HOME/.zshrc" ]; then
  RC_FILE="$USER_HOME/.zshrc"
else
  RC_FILE="$USER_HOME/.bashrc"
  touch "$RC_FILE"
fi

if ! grep -Fxq "$ALIAS_LINE" "$RC_FILE"; then
  echo "$ALIAS_LINE" >> "$RC_FILE"
  echo "🪄 Alias added to $RC_FILE"
  su -l "$USER_CTX" -c "source '$RC_FILE' 2>/dev/null || true"
  su -l "$USER_CTX" -c 'flite -voice rms -t "Alias s three c control registered."'
else
  echo "🪄 Alias already present in $RC_FILE"
  su -l "$USER_CTX" -c 'flite -voice rms -t "Alias exists. No changes made."'
fi

# 7. Final confirmation
echo "✅ Deployment complete. Launch with: s3cctl"
su -l "$USER_CTX" -c 'flite -voice rms -t "Deployment complete. Repeater interface is now operational."'
