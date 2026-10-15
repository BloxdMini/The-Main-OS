#!/bin/bash
set -euo pipefail

LOG_FILE="/var/log/nexus-network-monitor.log"
ALERT_FILE="/var/log/nexus-alerts.log"
KNOWN_DATA_EXFILL_PROCESSES="wget|curl|nc|ncat|socat|scp|rsync|ftp|sftp|ssh|telnet"
KNOWN_EXFILL_DOMAINS="pastebin|ghostbin|transfer.sh|file.io|anonfiles|mega.nz|mediafire|dropbox|drive.google"
SUSPICIOUS_PORTS="4444 5555 6666 7777 8888 9999 12345 31337 54321"

echo "============================================" | tee -a "$LOG_FILE"
echo "  NEXUS OS - Network Monitor" | tee -a "$LOG_FILE"
echo "  $(date)" | tee -a "$LOG_FILE"
echo "============================================" | tee -a "$LOG_FILE"

check_hidden_connections() {
    echo "[*] Checking for hidden connections..." | tee -a "$LOG_FILE"
    local connections
    connections=$(ss -tunap 2>/dev/null | grep -v "127.0.0.1" | grep -v "::1" || true)
    if [ -n "$connections" ]; then
        echo "[!] Active external connections detected:" | tee -a "$LOG_FILE"
        echo "$connections" | tee -a "$LOG_FILE"
    fi
}

check_data_exfiltration() {
    echo "[*] Checking for data exfiltration attempts..." | tee -a "$LOG_FILE"
    local suspicious
    suspicious=$(ps aux | grep -iE "$KNOWN_DATA_EXFILL_PROCESSES" | grep -v grep || true)
    if [ -n "$suspicious" ]; then
        echo "[!] Suspicious processes detected:" | tee -a "$LOG_FILE"
        echo "$suspicious" | tee -a "$LOG_FILE"
        echo "SUSPICIOUS_PROCESS: $suspicious" >> "$ALERT_FILE"
    fi
}

check_dns_queries() {
    echo "[*] Monitoring DNS queries..." | tee -a "$LOG_FILE"
    local dns_queries
    dns_queries=$(journalctl -u systemd-resolved --no-pager -n 100 2>/dev/null | grep -iE "$KNOWN_EXFILL_DOMAINS" || true)
    if [ -n "$dns_queries" ]; then
        echo "[!] Suspicious DNS queries detected:" | tee -a "$LOG_FILE"
        echo "$dns_queries" | tee -a "$LOG_FILE"
        echo "SUSPICIOUS_DNS: $dns_queries" >> "$ALERT_FILE"
    fi
}

check_suspicious_ports() {
    echo "[*] Checking for suspicious port usage..." | tee -a "$LOG_FILE"
    for port in $SUSPICIOUS_PORTS; do
        local port_check
        port_check=$(ss -tunap | grep ":$port " || true)
        if [ -n "$port_check" ]; then
            echo "[!] Suspicious port $port in use:" | tee -a "$LOG_FILE"
            echo "$port_check" | tee -a "$LOG_FILE"
            echo "SUSPICIOUS_PORT: $port - $port_check" >> "$ALERT_FILE"
        fi
    done
}

check_hidden_files() {
    echo "[*] Checking for hidden files in home directories..." | tee -a "$LOG_FILE"
    local hidden_files
    hidden_files=$(find /home -name ".*" -type f 2>/dev/null | head -20 || true)
    if [ -n "$hidden_files" ]; then
        echo "[!] Hidden files found:" | tee -a "$LOG_FILE"
        echo "$hidden_files" | tee -a "$LOG_FILE"
    fi
}

check_kernel_modules() {
    echo "[*] Checking for suspicious kernel modules..." | tee -a "$LOG_FILE"
    local modules
    modules=$(lsmod | grep -iE "rootkit|hide|keylogger|sniff" || true)
    if [ -n "$modules" ]; then
        echo "[!] Suspicious kernel modules detected:" | tee -a "$LOG_FILE"
        echo "$modules" | tee -a "$LOG_FILE"
        echo "SUSPICIOUS_MODULE: $modules" >> "$ALERT_FILE"
    fi
}

check_process_injection() {
    echo "[*] Checking for process injection..." | tee -a "$LOG_FILE"
    local processes
    processes=$(ps aux | grep -iE "gdb|strace|ltrace" | grep -v grep || true)
    if [ -n "$processes" ]; then
        echo "[!] Debug/injection tools detected:" | tee -a "$LOG_FILE"
        echo "$processes" | tee -a "$LOG_FILE"
    fi
}

check_open_files() {
    echo "[*] Checking for suspicious open files..." | tee -a "$LOG_FILE"
    local open_files
    open_files=$(lsof 2>/dev/null | grep -iE "password|secret|key|token|credential" || true)
    if [ -n "$open_files" ]; then
        echo "[!] Files with sensitive names opened:" | tee -a "$LOG_FILE"
        echo "$open_files" | tee -a "$LOG_FILE"
    fi
}

check_network_interfaces() {
    echo "[*] Checking network interfaces..." | tee -a "$LOG_FILE"
    local interfaces
    interfaces=$(ip link show | grep -iE "promisc|mon" || true)
    if [ -n "$interfaces" ]; then
        echo "[!] Promiscuous mode interfaces detected:" | tee -a "$LOG_FILE"
        echo "$interfaces" | tee -a "$LOG_FILE"
        echo "PROMISC_INTERFACE: $interfaces" >> "$ALERT_FILE"
    fi
}

check_hidden_processes() {
    echo "[*] Checking for hidden processes..." | tee -a "$LOG_FILE"
    local ps_count
    ps_count=$(ps aux | wc -l)
    local proc_count
    proc_count=$(ls /proc | grep -E "^[0-9]+$" | wc -l)
    if [ "$proc_count" -gt "$ps_count" ]; then
        echo "[!] Possible hidden processes detected!" | tee -a "$LOG_FILE"
        echo "PS count: $ps_count, /proc count: $proc_count" | tee -a "$LOG_FILE"
        echo "HIDDEN_PROCESS: ps=$ps_count proc=$proc_count" >> "$ALERT_FILE"
    fi
}

main() {
    check_hidden_connections
    check_data_exfiltration
    check_dns_queries
    check_suspicious_ports
    check_hidden_files
    check_kernel_modules
    check_process_injection
    check_open_files
    check_network_interfaces
    check_hidden_processes

    echo "[*] Network monitor scan complete." | tee -a "$LOG_FILE"
}

main "$@"
