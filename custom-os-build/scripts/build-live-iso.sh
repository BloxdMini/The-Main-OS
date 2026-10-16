#!/usr/bin/env bash
set -Eeuo pipefail

BUILD_DIR="${BUILD_DIR:-/build}"
OUTPUT_DIR="${OUTPUT_DIR:-/output}"
CHROOT_DIR="$BUILD_DIR/chroot"
ISO_DIR="$BUILD_DIR/iso"
CASPER_DIR="$ISO_DIR/casper"
BOOT_DIR="$ISO_DIR/boot/grub"

mkdir -p "$BUILD_DIR" "$OUTPUT_DIR"
rm -rf "$CHROOT_DIR" "$ISO_DIR"
mkdir -p "$CHROOT_DIR" "$CASPER_DIR" "$BOOT_DIR"

cleanup_mounts() {
    local mount_point
    for mount_point in "$CHROOT_DIR/run" "$CHROOT_DIR/sys" "$CHROOT_DIR/proc" "$CHROOT_DIR/dev/pts" "$CHROOT_DIR/dev"; do
        if mountpoint -q "$mount_point"; then
            umount -lf "$mount_point"
        fi
    done
}
trap cleanup_mounts EXIT

echo "[1/7] Installing Ubuntu base system..."
debootstrap --variant=minbase --arch=amd64 noble "$CHROOT_DIR" http://archive.ubuntu.com/ubuntu/

echo "[2/7] Preparing chroot..."
mkdir -p "$CHROOT_DIR/dev/pts" "$CHROOT_DIR/proc" "$CHROOT_DIR/sys" "$CHROOT_DIR/run"
cp /etc/resolv.conf "$CHROOT_DIR/etc/resolv.conf"
mount --bind /dev "$CHROOT_DIR/dev"
mount --bind /dev/pts "$CHROOT_DIR/dev/pts"
mount -t proc proc "$CHROOT_DIR/proc"
mount --bind /sys "$CHROOT_DIR/sys"
mount --bind /run "$CHROOT_DIR/run"

cat > "$CHROOT_DIR/usr/sbin/policy-rc.d" <<'POLICY'
#!/bin/sh
exit 101
POLICY
chmod +x "$CHROOT_DIR/usr/sbin/policy-rc.d"

cat > "$CHROOT_DIR/etc/apt/sources.list" <<'SOURCES'
deb http://archive.ubuntu.com/ubuntu/ noble main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ noble-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ noble-security main restricted universe multiverse
SOURCES

echo "[3/7] Installing desktop and security tools..."
chroot "$CHROOT_DIR" /usr/bin/env DEBIAN_FRONTEND=noninteractive bash -euc '
    apt-get update
    apt-get install -y --no-install-recommends \
        linux-generic casper systemd-sysv network-manager net-tools sudo \
        vim-tiny nano curl wget git \
        xserver-xorg lightdm xfce4 xfce4-terminal dbus-x11 plymouth \
        pulseaudio alsa-utils openssh-server ufw apparmor apparmor-utils \
        auditd rsyslog chrony tor \
        nmap sqlmap aircrack-ng wireshark tcpdump john hashcat binwalk \
        strace ltrace gdb python3 python3-pip python3-venv nodejs npm \
        golang-go openjdk-17-jdk ruby perl php lua5.4 lynis firejail
    apt-get clean
'
rm -f "$CHROOT_DIR/usr/sbin/policy-rc.d"

echo "[4/7] Configuring live session..."
cat > "$CHROOT_DIR/etc/casper.conf" <<'CASPER'
export USERNAME="nexus"
export USERFULLNAME="NEXUS OS"
export HOST="nexus"
CASPER

mkdir -p "$CHROOT_DIR/etc/lightdm/lightdm.conf.d" "$CHROOT_DIR/usr/local/bin"
cat > "$CHROOT_DIR/etc/lightdm/lightdm.conf.d/50-nexus-autologin.conf" <<'LIGHTDM'
[Seat:*]
autologin-user=nexus
autologin-user-timeout=0
LIGHTDM

install -m 0755 "$(dirname "$0")/network-monitor.sh" "$CHROOT_DIR/usr/local/bin/network-monitor"
install -m 0755 "$(dirname "$0")/security-hardening.sh" "$CHROOT_DIR/usr/local/bin/nexus-hardening"
install -m 0755 "$(dirname "$0")/tor-routing.sh" "$CHROOT_DIR/usr/local/bin/tor-routing"

echo "[5/7] Preparing live boot files..."
kernel=$(find "$CHROOT_DIR/boot" -maxdepth 1 -type f -name 'vmlinuz-*' -print | sort -V | tail -n 1)
initrd=$(find "$CHROOT_DIR/boot" -maxdepth 1 -type f -name 'initrd.img-*' -print | sort -V | tail -n 1)
if [[ -z "$kernel" || -z "$initrd" ]]; then
    echo "Kernel or initrd was not installed" >&2
    exit 1
fi
cp "$kernel" "$CASPER_DIR/vmlinuz"
cp "$initrd" "$CASPER_DIR/initrd"

cleanup_mounts
mksquashfs "$CHROOT_DIR" "$CASPER_DIR/filesystem.squashfs" -comp xz -noappend
if [[ ! -s "$CASPER_DIR/filesystem.squashfs" ]]; then
    echo "Casper live root filesystem was not created" >&2
    exit 1
fi
du -sx --block-size=1 "$CHROOT_DIR" | cut -f1 > "$CASPER_DIR/filesystem.size"

cat > "$BOOT_DIR/grub.cfg" <<'GRUB'
serial --unit=0 --speed=115200
terminal_input serial
terminal_output serial
set timeout=5
set default=0

menuentry "NEXUS OS (live)" {
    linux /casper/vmlinuz boot=casper live quiet splash console=ttyS0,115200n8 systemd.show_status=1 ---
    initrd /casper/initrd
}
GRUB

echo "[6/7] Building hybrid BIOS/UEFI ISO..."
grub-mkrescue -o "$OUTPUT_DIR/nexus-os.iso" "$ISO_DIR"
test -s "$OUTPUT_DIR/nexus-os.iso"

echo "[7/7] Build complete: $OUTPUT_DIR/nexus-os.iso"
