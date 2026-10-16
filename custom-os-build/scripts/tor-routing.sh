#!/bin/bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "Run as root"
    exit 1
fi

echo "============================================"
echo "  NEXUS OS - Tor Network Routing"
echo "============================================"

echo "[1/5] Configuring Tor..."
cat > /etc/tor/torrc << 'TOR'
SocksPort 9050
SocksPolicy accept 127.0.0.1
SocksPolicy reject *
ControlPort 9051
CookieAuthentication 1
CookieAuthFile /run/tor/control.authcookie
TOR

tor --verify-config -f /etc/tor/torrc

echo "[2/5] Setting up SOCKS proxy settings..."
cat > /etc/tor/torsocks.conf << 'TORSOCKS'
TorAddress 127.0.0.1
TorPort 9050
OnionAddrRange 127.42.42.0/24
TORSOCKS

echo "[3/5] Creating IP change script..."
cat > /usr/local/bin/tor-change-ip << 'CHANGEIP'
#!/bin/bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "Run as root" >&2
    exit 1
fi

cookie_file="/run/tor/control.authcookie"
if [ ! -r "$cookie_file" ]; then
    echo "Tor control cookie is unavailable; check that Tor is running." >&2
    exit 1
fi
cookie=$(od -An -v -tx1 "$cookie_file" | tr -d ' \n')
if [ -z "$cookie" ]; then
    echo "Tor control cookie is empty." >&2
    exit 1
fi

echo "Changing Tor IP..."
response=$(printf 'AUTHENTICATE %s\r\nSIGNAL NEWNYM\r\nQUIT\r\n' "$cookie" | nc -w 5 127.0.0.1 9051 | tr -d '\r')
if [ "$(printf '%s\n' "$response" | grep -c '^250 OK$' || true)" -lt 2 ]; then
    printf 'Tor rejected the new identity request:\n%s\n' "$response" >&2
    exit 1
fi

sleep 2
NEW_IP=$(curl -fsS --max-time 15 --socks5-hostname 127.0.0.1:9050 https://check.torproject.org/api/ip | grep -oP '"IP":"\K[^"]+' || true)
if [ -n "$NEW_IP" ]; then
    echo "New Tor IP: $NEW_IP"
else
    echo "A new Tor identity was requested, but its exit IP could not be verified." >&2
fi
CHANGEIP
chmod +x /usr/local/bin/tor-change-ip

echo "[4/5] Creating Tor check script..."
cat > /usr/local/bin/tor-check << 'TORCHECK'
#!/bin/bash
set -euo pipefail

echo "Checking Tor connection..."
TOR_STATUS=$(curl -fsS --max-time 10 --socks5-hostname 127.0.0.1:9050 https://check.torproject.org/api/ip 2>/dev/null || true)
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

echo "[5/5] Starting the packaged Tor service..."
systemctl enable tor@default.service
systemctl restart tor@default.service

echo "Tor SOCKS proxy configured at 127.0.0.1:9050. Applications must explicitly use the proxy."
echo "Use 'tor-change-ip' to get a new IP"
echo "Use 'tor-check' to verify connection"
