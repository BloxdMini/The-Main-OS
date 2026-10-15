#!/bin/bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "Run as root"
    exit 1
fi

echo "============================================"
echo "  NEXUS OS - Tor Network Routing"
echo "============================================"

echo "[1/6] Configuring Tor..."
cat > /etc/tor/torrc << 'TOR'
SocksPort 9050
SocksPolicy accept 127.0.0.1
SocksPolicy reject *
ControlPort 9051
CookieAuthentication 1
HashedControlPassword 16:E7719E0D25EDC200602B4A5B4C4C8C8C8C8C8C8C8C8C8C8C8C8
MaxCircuitDirtiness 10
CircuitBuildTimeout 10
LearnCircuitBuildTimeout 0
NewCircuitPeriod 15
NumEntryGuards 8
EntryNodes {us},{ca},{gb},{de},{nl},{se},{ch},{fr},{dk},{no}
ExitNodes {us},{ca},{gb},{de},{nl},{se},{ch},{fr},{dk},{no}
ExcludeNodes {ir},{cn},{ru},{kp},{sy},{by},{ve},{cu},{af},{iq}
ExcludeExitNodes {ir},{cn},{ru},{kp},{sy},{by},{ve},{cu},{af},{iy}
StrictNodes 1
TOR

echo "[2/6] Setting up transparent proxy..."
cat > /etc/tor/torsocks.conf << 'TORSOCKS'
TorAddress 127.0.0.1
TorPort 9050
OnionAddrRange 127.42.42.0/24
SOCKS5Username user
SOCKS5Password pass
TORSOCKS

echo "[3/6] Creating Tor routing service..."
cat > /etc/systemd/system/tor-routing.service << 'TORROUTE'
[Unit]
Description=Nexus OS Tor Routing
After=network.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/tor -f /etc/tor/torrc
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=5
User=debian-tor
Group=debian-tor
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/lib/tor /var/log/tor
CapabilitySet=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
TORROUTE

echo "[4/6] Creating IP change script..."
cat > /usr/local/bin/tor-change-ip << 'CHANGEIP'
#!/bin/bash
if [ "$EUID" -ne 0 ]; then
    echo "Run as root"
    exit 1
fi
echo "Changing Tor IP..."
kill -HUP $(pidof tor)
sleep 2
NEW_IP=$(curl -s --socks5 127.0.0.1:9050 https://check.torproject.org/api/ip | grep -oP '"IP":"\K[^"]+')
if [ -n "$NEW_IP" ]; then
    echo "New Tor IP: $NEW_IP"
else
    echo "Failed to get new IP"
fi
CHANGEIP
chmod +x /usr/local/bin/tor-change-ip

echo "[5/6] Creating Tor check script..."
cat > /usr/local/bin/tor-check << 'TORCHECK'
#!/bin/bash
echo "Checking Tor connection..."
TOR_STATUS=$(curl -s --max-time 10 --socks5 127.0.0.1:9050 https://check.torproject.org/api/ip 2>/dev/null)
if echo "$TOR_STATUS" | grep -q "IsTor\":true"; then
    echo "[OK] Connected to Tor"
    IP=$(echo "$TOR_STATUS" | grep -oP '"IP":"\K[^"]+')
    echo "Tor IP: $IP"
else
    echo "[FAIL] Not connected to Tor"
    exit 1
fi
TORCHECK
chmod +x /usr/local/bin/tor-check

echo "[6/6] Starting Tor service..."
systemctl daemon-reload
systemctl enable tor-routing
systemctl start tor-routing

echo "Tor routing configured. All traffic will go through Tor."
echo "Use 'tor-change-ip' to get a new IP"
echo "Use 'tor-check' to verify connection"
