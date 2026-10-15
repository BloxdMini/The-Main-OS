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
cat >> /etc/sysctl.conf << 'SYSCTL'
kernel.randomize_va_space=2
kernel.kptr_restrict=2
kernel.dmesg_restrict=1
kernel.printk=3 3 3 3
kernel.unprivileged_bpf_disabled=1
kernel.yama.ptrace_scope=1
kernel.unprivileged_userns_clone=0
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
net.ipv4.tcp_max_syn_backlog=65536
net.ipv4.tcp_synack_retries=2
net.ipv4.tcp_syn_retries=2
net.ipv4.tcp_rfc1337=1
net.ipv4.tcp_fin_timeout=15
net.ipv4.tcp_keepalive_time=300
net.ipv4.tcp_keepalive_probes=5
net.ipv4.tcp_keepalive_intvl=15
net.core.netdev_max_backlog=65536
net.core.somaxconn=65535
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_wmem=4096 65536 16777216
net.ipv4.tcp_congestion_control=cubic
net.ipv4.tcp_notsent_lowat=16384
net.ipv4.tcp_fastopen=3
net.ipv4.tcp_mtu_probing=1
net.ipv4.tcp_timestamps=0
net.ipv4.tcp_sack=1
net.ipv4.tcp_fack=1
net.ipv4.tcp_ecn=1
net.ipv4.tcp_tw_reuse=1
net.ipv4.ip_local_port_range=1024 65535
net.ipv4.tcp_max_tw_buckets=1440000
net.ipv4.tcp_abort_on_overflow=1
net.netfilter.nf_conntrack_max=2000000
net.netfilter.nf_conntrack_tcp_timeout_established=3600
net.netfilter.nf_conntrack_udp_timeout=30
net.netfilter.nf_conntrack_udp_timeout_stream=60
net.bridge.bridge-nf-call-iptables=0
net.bridge.bridge-nf-call-ip6tables=0
net.bridge.bridge-nf-call-arptables=0
SYSCTL

sysctl -p

echo "[2/8] Hardening SSH..."
cat > /etc/ssh/sshd_config.d/hardening.conf << 'SSH'
Protocol 2
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
systemctl disable bluetooth
systemctl disable cups
systemctl disable avahi-daemon

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
