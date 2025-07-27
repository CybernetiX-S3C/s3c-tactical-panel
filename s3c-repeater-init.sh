#!/usr/bin/env bash

# === S3C REPEATER INITIALIZER v4.0 (Aether) ===
SCRIPT_VERSION="v4.0 (Aether)" # Updated to Aether
LOGFILE="/var/log/s3c-repeater.log" # Corrected logfile path, it was .og
SESSION_FILE="/tmp/s3c-session.conf"
USER_CTX="${SUDO_USER:-$USER}"

# === S3C Auto-Cleanup Function (To be run in background) ===
# This function now focuses purely on log maintenance, as iptables flush is
# handled at init time.
s3c_auto_cleanup() {
    local SLEEP_TIME=$((4 * 3600)) # 4 hours in seconds
    echo "Starting auto-cleanup daemon (every 4 hours, logs only)..." | tee -a "$LOGFILE"
    while true; do
        echo "🧹 Auto-cleanup initiated by daemon (logs only)..." | tee -a "$LOGFILE"

        # Truncate Large Active System Logs
        echo "  Truncating common active log files (auto-cleanup)..." | tee -a "$LOGFILE"
        sudo truncate -s 0 /var/log/syslog
        sudo truncate -s 0 /var/log/kern.log
        sudo truncate -s 0 /var/log/auth.log
        sudo truncate -s 0 /var/log/daemon.log
        sudo truncate -s 0 /var/log/debug.log
        sudo truncate -s 0 /var/log/messages
        sudo truncate -s 0 /var/log/boot.log 2>/dev/null || true
        sudo truncate -s 0 /var/log/alternatives.log 2>/dev/null || true
        sudo truncate -s 0 /var/log/s3c-repeater.log

        # Vacuum System Journal Logs Aggressively
        echo "  Aggressively vacuuming systemd journal logs (auto-cleanup)..." | tee -a "$LOGFILE"
        sudo journalctl --vacuum-size=50M
        sudo journalctl --vacuum-time=12h

        echo "✅ Auto-cleanup cycle complete. Next cycle in 4 hours." | tee -a "$LOGFILE"
        sleep "$SLEEP_TIME"
    done
}
# ===========================================================


# 1) Load session
CONFIG_SCRIPT="/usr/local/bin/s3c-repeater-config"
source "$CONFIG_SCRIPT"
if ! load_config "$SESSION_FILE"; then
  echo "❌ Failed to load session config. Aborting." | tee -a "$LOGFILE"
  su -l "$USER_CTX" -c 'flite -voice rms -t "Failed to load repeater session. Aborting initialization."'
  exit 1
fi

# === Pre-flight Interface Check ===
echo "🔎 Performing interface pre-flight check..." | tee -a "$LOGFILE"
if ! ip link show "$HOTSPOT_IF" &>/dev/null; then
    echo "❌ Hotspot interface ($HOTSPOT_IF) not found or not ready. Aborting." | tee -a "$LOGFILE"
    su -l "$USER_CTX" -c 'flite -voice rms -t "Hotspot interface not detected. Aborting initialization."'
    exit 1
fi
if ! ip link show "$UPLINK_IF" &>/dev/null; then
    echo "❌ Uplink interface ($UPLINK_IF) not found or not ready. Aborting." | tee -a "$LOGFILE"
    su -l "$USER_CTX" -c 'flite -voice rms -t "Uplink interface not detected. Aborting initialization."'
    exit 1
fi
echo "✅ Interfaces verified. Proceeding with initialization." | tee -a "$LOGFILE"
# ==================================

# 2) Startup announcement
su -l "$USER_CTX" -c 'flite -voice rms -t "Initializing repeater v Aether. WPA two AES and DHCP are now engaging."'
echo "🧬 Init v${SCRIPT_VERSION} — $HOTSPOT_IF ↔ $UPLINK_IF | SSID: $SSID" | tee -a "$LOGFILE"
echo "📅 $(date)" | tee -a "$LOGFILE"

# === S3C LOG PURIFIER INTEGRATION (Pre-Init) ===
echo "🧹 Performing pre-init system cleanup (logs only)..." | tee -a "$LOGFILE"

# Truncate Large Active System Logs
echo "  Truncating common active log files..." | tee -a "$LOGFILE"
sudo truncate -s 0 /var/log/syslog
sudo truncate -s 0 /var/log/kern.log
sudo truncate -s 0 /var/log/auth.log
sudo truncate -s 0 /var/log/daemon.log
sudo truncate -s 0 /var/log/debug.log
sudo truncate -s 0 /var/log/messages
sudo truncate -s 0 /var/log/boot.log 2>/dev/null || true # Optional, may not exist
sudo truncate -s 0 /var/log/alternatives.log 2>/dev/null || true # Optional, may not exist
sudo truncate -s 0 /var/log/s3c-repeater.log # Your S3C log file

# Vacuum System Journal Logs Aggressively
echo "  Aggressively vacuuming systemd journal logs..." | tee -a "$LOGFILE"
sudo journalctl --vacuum-size=50M  # Limit total journal logs to 50MB
sudo journalctl --vacuum-time=12h  # Remove logs older than 12 hours
echo "✅ Pre-init cleanup complete." | tee -a "$LOGFILE"
# ===============================================

# 3) Kill conflicting services for hotspot interface and flush iptables (Comprehensive Pre-Flight Flush)
# Rebooting NetworkManager to ensure no hiccups
echo "🔄 Rebooting NetworkManager to ensure no hiccups (Pre-flight)..." | tee -a "$LOGFILE"
sudo systemctl restart NetworkManager

# Priority time count to ensure NetworkManager is online and pushing traffic
echo "⏳ Waiting 20 seconds for NetworkManager to stabilize (Pre-flight)..." | tee -a "$LOGFILE"
sleep 20

# First, set default policies to ACCEPT to ensure no traffic is implicitly blocked
echo "  Setting default iptables policies to ACCEPT (Pre-flight)..." | tee -a "$LOGFILE"
sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT
sudo ip6tables -P INPUT ACCEPT
sudo ip6tables -P FORWARD ACCEPT
sudo ip6tables -P OUTPUT ACCEPT

# Next, flush all rules in all chains for IPv4 and IPv6
echo "  Flushing all iptables rules (IPv4 & IPv6) (Pre-flight)..." | tee -a "$LOGFILE"
sudo iptables -F
sudo iptables -X
sudo iptables -Z
sudo ip6tables -F
sudo ip6tables -X
sudo ip6tables -Z

# Clear all NAT rules (crucial for repeater functionality)
echo "  Clearing all NAT, RAW, and MANGLE table rules (Pre-flight)..." | tee -a "$LOGFILE"
sudo iptables -t nat -F
sudo iptables -t nat -X
sudo iptables -t raw -F
sudo iptables -t raw -X
sudo iptables -t mangle -F
sudo iptables -t mangle -X
echo "  ✅ Pre-flight iptables and ip6tables flush complete." | tee -a "$LOGFILE"


sudo pkill -f "wpa_supplicant.*${HOTSPOT_IF}" 2>/dev/null || true
sudo nmcli device set "$HOTSPOT_IF" managed no 2>/dev/null || true
sudo systemctl stop dnsmasq hostapd

# Explicitly ensure uplink interface is managed and connected by NetworkManager
# This helps maintain stability for the wlan1 (RTL8812AU) adapter
echo "Ensuring uplink interface ($UPLINK_IF) is managed and connected by NetworkManager..." | tee -a "$LOGFILE"
sudo nmcli device set "$UPLINK_IF" managed yes 2>/dev/null || true
sudo nmcli device connect "$UPLINK_IF" 2>/dev/null || true
# Give it a moment to stabilize if it just connected
sleep 5
echo "Uplink interface management confirmed." | tee -a "$LOGFILE"

# 4) Configure hotspot interface
sudo ip link set "$HOTSPOT_IF" up
sudo ip addr flush dev "$HOTSPOT_IF"
sudo ip addr add 192.168.50.1/24 dev "$HOTSPOT_IF"

# 5) NAT and forwarding
# These rules will be applied *after* the initial comprehensive flush in Section 3.
sudo iptables -A FORWARD -i "$HOTSPOT_IF" -o "$UPLINK_IF" -j ACCEPT
sudo iptables -A FORWARD -i "$UPLINK_IF" -o "$HOTSPOT_IF" \
  -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -t nat -A POSTROUTING -o "$UPLINK_IF" -j MASQUERADE
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward

# 6) Flush old DHCP leases
sudo rm -f /var/lib/misc/dnsmasq.leases

# 7) Configure hostapd
sudo tee /etc/hostapd/hostapd.conf > /dev/null <<EOF
country_code=US
ieee80211d=1
ieee80211h=1
interface=$HOTSPOT_IF
driver=nl80211
ssid=$SSID
hw_mode=g
channel=6
ieee80211n=1
ht_capab=[HT20][SHORT-GI-20][DSSS_CCK-40]
wmm_enabled=1
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=$PASSPHRASE
wpa_key_mgmt=WPA-PSK
wpa_pairwise=CCMP
rsn_pairwise=CCMP
EOF

# 8) Configure dnsmasq for DHCP
sudo tee /etc/dnsmasq.d/s3c.conf > /dev/null <<EOF
interface=$HOTSPOT_IF
bind-interfaces
listen-address=192.168.50.1
dhcp-authoritative
dhcp-range=192.168.50.50,192.168.50.150,255.255.255.0,12h
dhcp-option=3,192.168.50.1
dhcp-option=6,192.168.50.1
log-dhcp
EOF

# 9) Start services
sudo systemctl restart dnsmasq hostapd

# === Service Activation Verification ===
echo "Verify essential services are active..." | tee -a "$LOGFILE"
SERVICE_CHECK_ATTEMPTS=3
SERVICE_CHECK_INTERVAL=2

for i in $(seq 1 $SERVICE_CHECK_ATTEMPTS); do
    DNSMASQ_STATUS=$(systemctl is-active dnsmasq)
    HOSTAPD_STATUS=$(systemctl is-active hostapd)

    if [[ "$DNSMASQ_STATUS" == "active" && "$HOSTAPD_STATUS" == "active" ]]; then
        echo "✅ dnsmasq and hostapd are active." | tee -a "$LOGFILE"
        break
    else
        echo "⚠️ Services not fully active (Attempt $i/$SERVICE_CHECK_ATTEMPTS). Retrying in ${SERVICE_CHECK_INTERVAL}s..." | tee -a "$LOGFILE"
        sleep "$SERVICE_CHECK_INTERVAL"
    fi

    if [[ "$i" -eq "$SERVICE_CHECK_ATTEMPTS" ]]; then
        echo "❌ Failed to activate dnsmasq or hostapd after multiple attempts." | tee -a "$LOGFILE"
        echo "dnsmasq status: $DNSMASQ_STATUS" | tee -a "$LOGFILE"
        echo "hostapd status: $HOSTAPD_STATUS" | tee -a "$LOGFILE"
        su -l "$USER_CTX" -c 'flite -voice rms -t "Critical services failed to start. Review logs."'
        # Decide here if you want to exit or continue with degraded functionality
        # For now, we will allow it to continue, but flag the issue clearly.
    fi
done
# =======================================

# 10) Confirm live AP
su -l "$USER_CTX" -c 'flite -voice rms -t "Access point is live. WPA two and DHCP online."'
echo "✅ Hotspot \"$SSID\" active on $HOTSPOT_IF" | tee -a "$LOGFILE"

# 11) Uplink test
echo "🧪 Testing uplink ($UPLINK_IF)..." | tee -a "$LOGFILE"
if ping -c2 -W2 8.8.8.8 &>/dev/null; then
  echo "✅ Internet reachable via $UPLINK_IF" | tee -a "$LOGFILE"
  su -l "$USER_CTX" -c 'flite -voice rms -t "Internet reachable on uplink."'
else
  echo "❌ No internet on $UPLINK_IF" | tee -a "$LOGFILE"
  su -l "$USER_CTX" -c 'flite -voice rms -t "No internet on uplink."'
fi

# 12) List clients
echo "🧠 Scanning connected clients (ARP)..." | tee -a "$LOGFILE"
arp -n | grep -v incomplete | tee -a "$LOGFILE"
su -l "$USER_CTX" -c 'flite -voice rms -t "Client list updated."'

# === Start Auto-Cleanup Daemon ===
s3c_auto_cleanup & # Run the function in the background
AUTO_CLEANUP_PID=$! # Capture the PID of the background process
echo "$AUTO_CLEANUP_PID" > "/tmp/s3c_auto_cleanup.pid" # Save PID to a temporary file
echo "Started auto-cleanup daemon with PID: $AUTO_CLEANUP_PID" | tee -a "$LOGFILE"
# =================================

# 13) Remove leftover bridge
if ip link show "$HOTSPOT_IF" | grep -q master; then
  sudo ip link set "$HOTSPOT_IF" nomaster
  sudo ip link delete br0
  echo "🧹 Residual bridge removed." | tee -a "$LOGFILE"
fi

# 14) Finish
su -l "$USER_CTX" -c 'flite -voice rms -t "Repeater initialization complete. Aether is nominal."'
echo "🛰️ Init v${SCRIPT_VERSION} complete." | tee -a "$LOGFILE"
