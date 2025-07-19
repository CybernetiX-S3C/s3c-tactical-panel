#!/usr/bin/env bash

# === S3C REPEATER INITIALIZER v3.0 (Orion) ===
SCRIPT_VERSION="v3.0 (Orion)"
LOGFILE="/var/log/s3c-repeater.log"
SESSION_FILE="/tmp/s3c-session.conf"
USER_CTX="${SUDO_USER:-$USER}"

# 1) Load session
if [ ! -f "$SESSION_FILE" ]; then
  echo "❌ No session config found. Aborting." | tee -a "$LOGFILE"
  su -l "$USER_CTX" -c 'flite -voice rms -t "No repeater session found. Aborting initialization."'
  exit 1
fi
source "$SESSION_FILE"

# 2) Startup announcement
su -l "$USER_CTX" -c 'flite -voice rms -t "Initializing repeater v Orion. WPA two AES and DHCP are now engaging."'
echo "🧬 Init v${SCRIPT_VERSION} — $HOTSPOT_IF ↔ $UPLINK_IF | SSID: $SSID" | tee -a "$LOGFILE"
echo "📅 $(date)" | tee -a "$LOGFILE"

# 3) Kill conflicting services
sudo pkill -f "wpa_supplicant.*${HOTSPOT_IF}" 2>/dev/null || true
sudo nmcli device set "$HOTSPOT_IF" managed no 2>/dev/null || true
sudo systemctl stop dnsmasq hostapd

# 4) Configure hotspot interface
sudo ip link set "$HOTSPOT_IF" up
sudo ip addr flush dev "$HOTSPOT_IF"
sudo ip addr add 192.168.50.1/24 dev "$HOTSPOT_IF"

# 5) NAT and forwarding
sudo iptables -F
sudo iptables -t nat -F
sudo iptables -X
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

# 13) Remove leftover bridge
if ip link show "$HOTSPOT_IF" | grep -q master; then
  sudo ip link set "$HOTSPOT_IF" nomaster
  sudo ip link delete br0
  echo "🧹 Residual bridge removed." | tee -a "$LOGFILE"
fi

# 14) Finish
su -l "$USER_CTX" -c 'flite -voice rms -t "Repeater initialization complete. Orion is nominal."'
echo "🛰️ Init v${SCRIPT_VERSION} complete." | tee -a "$LOGFILE"
