#!/bin/bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "Run as root"
    exit 1
fi

echo "============================================"
echo "  NEXUS OS - Security Hardening Script"
echo "============================================"

echo "[1/8] Applying kernel hardening..."
sysctl_config="/etc/sysctl.d/99-nexus-hardening.conf"
cat > "$sysctl_config" << 'SYSCTL'
kernel.randomize_va_space=2
kernel.kptr_restrict=2
kernel.dmesg_restrict=1
kernel.printk=3 3 3 3
kernel.unprivileged_bpf_disabled=1
kernel.yama.ptrace_scope=1
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv6.conf.all.accept_redirects=0
net.ipv6.conf.default.accept_redirects=0
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.default.send_redirects=0
net.ipv4.conf.all.accept_source_route=0
net.ipv4.conf.default.accept_source_route=0
net.ipv6.conf.all.accept_source_route=0
net.ipv6.conf.default.accept_source_route=0
net.ipv4.conf.all.log_martians=1
net.ipv4.conf.default.log_martians=1
net.ipv4.icmp_echo_ignore_broadcasts=1
net.ipv4.icmp_ignore_bogus_error_responses=1
net.ipv4.tcp_syncookies=1
SYSCTL

sysctl -p "$sysctl_config"

echo "[2/8] Hardening SSH..."
cat > /etc/ssh/sshd_config.d/hardening.conf << 'SSH'
PermitRootLogin no
MaxAuthTries 3
MaxSessions 5
LoginGraceTime 30
ClientAliveInterval 300
ClientAliveCountMax 2
AllowTcpForwarding no
X11Forwarding no
AllowAgentForwarding no
PermitEmptyPasswords no
HostbasedAuthentication no
IgnoreRhosts yes
HostbasedUsesNameFromPacketOnly no
PermitUserEnvironment no
Banner /etc/ssh/banner
SSH
cat > /etc/ssh/banner << 'BANNER'
NEXUS OS authorized access only.
BANNER
sshd -t

echo "[3/8] Configuring firewall..."
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw --force enable

echo "[4/8] Enabling AppArmor..."
aa-enforce /etc/apparmor.d/*
systemctl enable apparmor

echo "[5/8] Configuring audit rules..."
cat > /etc/audit/rules.d/nexus.rules << 'AUDIT'
-w /etc/passwd -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/sudoers -p wa -k sudoers
-w /etc/sudoers.d/ -p wa -k sudoers
-w /var/log/auth.log -p wa -k auth
-w /var/log/syslog -p wa -k syslog
-w /var/log/audit/ -p wa -k audit
-w /etc/ssh/ -p wa -k sshd
-w /etc/pam.d/ -p wa -k pam
-w /etc/security/ -p wa -k security
-w /usr/bin/ -p wa -k binaries
-w /usr/sbin/ -p wa -k sbin
-w /bin/ -p wa -k binaries
-w /sbin/ -p wa -k sbin
-w /lib/ -p wa -k libraries
-w /lib64/ -p wa -k libraries
-w /etc/ld.so.conf -p wa -k ldconfig
-w /etc/ld.so.conf.d/ -p wa -k ldconfig
-a always,exit -F arch=b64 -S execve -k exec
-a always,exit -F arch=b64 -S open -S openat -S creat -S truncate -S ftruncate -k file_access
-a always,exit -F arch=b64 -S socket -S connect -S bind -S accept -S listen -k network
-a always,exit -F arch=b64 -S mount -S umount2 -k mounts
-a always,exit -F arch=b64 -S chmod -S fchmod -S fchmodat -k permissions
-a always,exit -F arch=b64 -S chown -S fchown -S fchownat -S lchown -k ownership
-a always,exit -F arch=b64 -S setuid -S setgid -S setreuid -S setregid -S setresuid -S setresgid -k privilege_escalation
-a always,exit -F arch=b64 -S ptrace -k ptrace
-a always,exit -F arch=b64 -S init_module -S finit_module -S delete_module -k modules
-a always,exit -F arch=b64 -S reboot -k reboot
AUDIT

echo "[6/8] Disabling unnecessary services..."
for service in bluetooth cups avahi-daemon; do
    if systemctl cat "$service.service" >/dev/null 2>&1; then
        systemctl disable "$service.service"
    else
        echo "Skipping $service: service is not installed."
    fi
done

echo "[7/8] Setting up automatic security updates..."
cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'UNATTENDED'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}";
    "${distro_id}:${distro_codename}-security";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Mail "root";
UNATTENDED

echo "[8/8] Running final security scan..."
if command -v lynis &> /dev/null; then
    lynis audit system --quick
fi

echo "Security hardening complete. Reboot recommended."
