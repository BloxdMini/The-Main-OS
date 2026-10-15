# NEXUS OS - Custom Linux Distribution

A security-focused Linux distribution combining Ubuntu, Kali Linux, and Termux tooling.

## Features

- Ubuntu 24.04 base with Kali Linux security tools
- Tor network routing (all traffic through Tor)
- Network monitoring for data exfiltration detection
- Security hardening (kernel, SSH, firewall, AppArmor, audit)
- XFCE desktop environment
- Custom bootloader and branding
- Pre-installed development tools

## Requirements

- Docker Desktop for Windows (or any Docker-capable system)
- 20GB free disk space
- 4GB RAM minimum

## Building

1. Install Docker Desktop
2. Open PowerShell in this directory
3. Run:

```powershell
docker build -t nexus-os-builder .
docker run --rm -v "${PWD}\output:/output" nexus-os-builder
```

The ISO will be in `output\nexus-os.iso`

## Usage

- Burn the ISO to USB with Rufus or balenaEtcher
- Boot from USB
- Default user: `nexus` / password: `nexus`
- Change password immediately after first login

## Security Tools Included

- Metasploit, Nmap, Burp Suite, SQLmap
- Aircrack-ng, John the Ripper, Hashcat
- Wireshark, Tcpdump, Volatility
- chkrootkit, rkhunter, Lynis
- Firejail, Flatpak, Snap

## Tor Commands

- `tor-check` - Verify Tor connection
- `tor-change-ip` - Get new Tor IP
- `network-monitor` - Run security scan
- `nexus-hardening` - Run security hardening

## Network Monitor

Run `network-monitor` regularly to detect:
- Hidden connections
- Data exfiltration attempts
- Suspicious DNS queries
- Promiscuous mode interfaces
- Hidden processes
- Suspicious kernel modules

## Legal Notice

This OS is for authorized security testing and education only.
