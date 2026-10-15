#!/bin/bash
set -euo pipefail

BUILD_DIR="/build"
OUTPUT_DIR="/output"
CHROOT_DIR="$BUILD_DIR/chroot"
ISO_DIR="$BUILD_DIR/iso"
CONFIG_DIR="$BUILD_DIR/configs"
BRANDING_DIR="$BUILD_DIR/branding"

mkdir -p "$OUTPUT_DIR" "$CHROOT_DIR" "$ISO_DIR"

echo "============================================"
echo "  NEXUS OS - Custom ISO Build System"
echo "  Ubuntu + Kali + Termux Hybrid"
echo "============================================"

echo "[1/10] Installing base system..."
debootstrap --variant=minbase --arch=amd64 noble "$CHROOT_DIR" http://archive.ubuntu.com/ubuntu/

echo "[2/10] Configuring base system..."
mount --bind /dev "$CHROOT_DIR/dev"
mount --bind /dev/pts "$CHROOT_DIR/dev/pts"
mount --bind /proc "$CHROOT_DIR/proc"
mount --bind /sys "$CHROOT_DIR/sys"
mount --bind /run "$CHROOT_DIR/run"

cat > "$CHROOT_DIR/etc/apt/sources.list" << 'SOURCES'
deb http://archive.ubuntu.com/ubuntu/ noble main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ noble-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ noble-security main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ noble-backports main restricted universe multiverse
deb http://http.kali.org/kali kali-rolling main non-free-firmware
SOURCES

cat > "$CHROOT_DIR/etc/apt/preferences.d/kali" << 'KALIPREF'
Package: *
Pin: release o=Kali,a=kali-rolling
Pin-Priority: 100
KALIPREF

chroot "$CHROOT_DIR" /bin/bash -c '
    apt-get update
    apt-get install -y linux-image-generic linux-headers-generic grub-pc-bin grub-efi-amd64-bin systemd systemd-sysv network-manager net-tools sudo vim nano curl wget git xserver-xorg x11-xserver-utils lightdm xfce4 xfce4-terminal firefox-esr pulseaudio alsa-utils firmware-linux-free openssh-server ufw apparmor apparmor-utils auditd rsyslog chrony policykit-1 dbus polkitd accountsservice cups avahi-daemon bluetooth wpasupplicant iw crda rfkill plymouth plymouth-theme-ubuntu-text console-setup keyboard-configuration locales tzdata bash-completion command-not-found man-db info doc-base ubuntu-standard ubuntu-minimal ubuntu-server ubuntu-desktop-minimal ubuntu-desktop ubuntu-restricted-addons ubuntu-restricted-extras libavcodec-extra libdvd-pkg fonts-ubuntu fonts-ubuntu-console fonts-ubuntu-title ubuntu-mono ubuntu-wallpapers ubuntu-wallpapers-noble ubuntu-keyring ubuntu-advantage-tools ubuntu-report popularity-contest apport apport-symptoms whoopsie systemd-coredump systemd-timesyncd systemd-resolved systemd-networkd systemd-oomd systemd-userdbd systemd-homed systemd-portabled systemd-stub systemd-sysupdate systemd-repart systemd-veritysetup systemd-integritysetup systemd-cryptsetup systemd-mountfsd systemd-fstab-setup systemd-growfs systemd-makefs systemd-nspawn systemd-machined systemd-importd systemd-exportd systemd-remoted systemd-pcrextend systemd-pstore systemd-backlight systemd-rfkill systemd-udevd systemd-udev-settle systemd-udev-trigger systemd-udev-rules systemd-udev-hwdb systemd-udev-net systemd-udev-kmod
    apt-get install -y tor torbrowser-launcher
    apt-get install -y nmap masscan zenmap
    apt-get install -y metasploit-framework
    apt-get install -y sqlmap
    apt-get install -y nikto dirb gobuster
    apt-get install -y hydra medusa
    apt-get install -y aircrack-ng reaver bully
    apt-get install -y wireshark tshark tcpdump
    apt-get install -y burpsuite
    apt-get install -y john hashcat
    apt-get install -y binwalk foremost
    apt-get install -y ghidra
    apt-get install -y radare2 cutter
    apt-get install -y strace ltrace gdb
    apt-get install -y volatility3
    apt-get install -y sleuthkit autopsy
    apt-get install -y chkrootkit rkhunter
    apt-get install -y lynis
    apt-get install -y tiger
    apt-get install -y bastille
    apt-get install -y firejail
    apt-get install -y bubblewrap
    apt-get install -y flatpak
    apt-get install -y snapd
    apt-get install -y appimage-launcher
    apt-get install -y proot proot-distro
    apt-get install -y termux-tools
    apt-get install -y python3 python3-pip python3-venv
    apt-get install -y nodejs npm
    apt-get install -y rustc cargo
    apt-get install -y golang-go
    apt-get install -y openjdk-17-jdk
    apt-get install -y ruby
    apt-get install -y perl
    apt-get install -y php
    apt-get install -y lua5.4
    apt-get install -y r-base
    apt-get install -y julia
    apt-get install -y octave
    apt-get install -y scilab
    apt-get install -y geogebra
    apt-get install -y kicad
    apt-get install -y freecad
    apt-get install -y openscad
    apt-get install -y inkscape
    apt-get install -y gimp
    apt-get install -y krita
    apt-get install -y blender
    apt-get install -y kdenlive
    apt-get install -y obs-studio
    apt-get install -y audacity
    apt-get install -y Ardour
    apt-get install -y lmms
    apt-get install -y rosegarden
    apt-get install -y musescore
    apt-get install -y denemo
    apt-get install -y frescobaldi
    apt-get install -y denemo
    apt-get install -y musescore
    apt-get install -y rosegarden
    apt-get install -y lmms
    apt-get install -y audacity
    apt-get install -y obs-studio
    apt-get install -y kdenlive
    apt-get install -y blender
    apt-get install -y krita
    apt-get install -y gimp
    apt-get install -y inkscape
    apt-get install -y openscad
    apt-get install -y freecad
    apt-get install -y kicad
    apt-get install -y geogebra
    apt-get install -y scilab
    apt-get install -y octave
    apt-get install -y julia
    apt-get install -y r-base
    apt-get install -y lua5.4
    apt-get install -y php
    apt-get install -y perl
    apt-get install -y ruby
    apt-get install -y openjdk-17-jdk
    apt-get install -y golang-go
    apt-get install -y rustc cargo
    apt-get install -y nodejs npm
    apt-get install -y python3 python3-pip python3-venv
    apt-get install -y proot proot-distro termux-tools
    apt-get install -y flatpak snapd appimage-launcher
    apt-get install -y firejail bubblewrap
    apt-get install -y bastille tiger lynis chkrootkit rkhunter
    apt-get install -y volatility3 sleuthkit autopsy
    apt-get install -y strace ltrace gdb radare2 cutter ghidra
    apt-get install -y binwalk foremost john hashcat
    apt-get install -y burpsuite wireshark tshark tcpdump
    apt-get install -y aircrack-ng reaver bully hydra medusa
    apt-get install -y nikto dirb gobuster sqlmap metasploit-framework
    apt-get install -y nmap masscan zenmap tor torbrowser-launcher
    apt-get install -y vim nano curl wget git sudo
    apt-get install -y xfce4 xfce4-terminal lightdm xserver-xorg x11-xserver-utils
    apt-get install -y firefox-esr pulseaudio alsa-utils
    apt-get install -y firmware-linux-free openssh-server
    apt-get install -y ufw apparmor apparmor-utils auditd rsyslog chrony
    apt-get install -y policykit-1 dbus polkitd accountsservice cups avahi-daemon
    apt-get install -y bluetooth wpasupplicant iw crda rfkill
    apt-get install -y plymouth plymouth-theme-ubuntu-text console-setup
    apt-get install -y keyboard-configuration locales tzdata bash-completion
    apt-get install -y command-not-found man-db info doc-base
    apt-get install -y ubuntu-standard ubuntu-minimal ubuntu-server
    apt-get install -y ubuntu-desktop-minimal ubuntu-desktop
    apt-get install -y ubuntu-restricted-addons ubuntu-restricted-extras
    apt-get install -y libavcodec-extra libdvd-pkg
    apt-get install -y fonts-ubuntu fonts-ubuntu-console fonts-ubuntu-title ubuntu-mono
    apt-get install -y ubuntu-wallpapers ubuntu-wallpapers-noble ubuntu-keyring
    apt-get install -y ubuntu-advantage-tools ubuntu-report popularity-contest
    apt-get install -y apport apport-symptoms whoopsie
    apt-get install -y systemd-coredump systemd-timesyncd systemd-resolved
    apt-get install -y systemd-networkd systemd-oomd systemd-userdbd systemd-homed
    apt-get install -y systemd-portabled systemd-stub systemd-sysupdate
    apt-get install -y systemd-repart systemd-veritysetup systemd-integritysetup
    apt-get install -y systemd-cryptsetup systemd-mountfsd systemd-fstab-setup
    apt-get install -y systemd-growfs systemd-makefs systemd-nspawn
    apt-get install -y systemd-machined systemd-importd systemd-exportd
    apt-get install -y systemd-remoted systemd-pcrextend systemd-pstore
    apt-get install -y systemd-backlight systemd-rfkill systemd-udevd
    apt-get install -y systemd-udev-settle systemd-udev-trigger
    apt-get install -y systemd-udev-rules systemd-udev-hwdb
    apt-get install -y systemd-udev-net systemd-udev-kmod
'

echo "[3/10] Copying configs..."
cp -r "$CONFIG_DIR"/* "$CHROOT_DIR/etc/"
cp -r "$BRANDING_DIR"/* "$CHROOT_DIR/usr/share/"

echo "[4/10] Installing Kali tools..."
chroot "$CHROOT_DIR" /bin/bash -c '
    apt-get update
    apt-get install -y kali-linux-default kali-linux-headless kali-tools-web kali-tools-database kali-tools-fuzzing kali-tools-passwords kali-tools-post-exploitation kali-tools-exploitation kali-tools-sniffing-spoofing kali-tools-wireless kali-tools-bluetooth kali-tools-rfid kali-tools-forensics kali-tools-reporting kali-tools-social-engineering kali-tools-information-gathering kali-tools-vulnerability-analysis kali-tools-stress-testing kali-tools-hardware kali-tools-reverse-engineering kali-tools-crypto kali-tools-fuzzing kali-tools-wireless kali-tools-bluetooth kali-tools-rfid kali-tools-forensics kali-tools-reporting kali-tools-social-engineering kali-tools-information-gathering kali-tools-vulnerability-analysis kali-tools-stress-testing kali-tools-hardware kali-tools-reverse-engineering kali-tools-crypto
'

echo "[5/10] Setting up Tor routing..."
cp "$BUILD_DIR/scripts/tor-routing.sh" "$CHROOT_DIR/usr/local/bin/tor-routing"
chmod +x "$CHROOT_DIR/usr/local/bin/tor-routing"

echo "[6/10] Setting up network monitor..."
cp "$BUILD_DIR/scripts/network-monitor.sh" "$CHROOT_DIR/usr/local/bin/network-monitor"
chmod +x "$CHROOT_DIR/usr/local/bin/network-monitor"

echo "[7/10] Setting up security hardening..."
cp "$BUILD_DIR/scripts/security-hardening.sh" "$CHROOT_DIR/usr/local/bin/nexus-hardening"
chmod +x "$CHROOT_DIR/usr/local/bin/nexus-hardening"

echo "[8/10] Configuring bootloader..."
chroot "$CHROOT_DIR" /bin/bash -c '
    grub-install --target=i386-pc /dev/sda
    grub-install --target=x86_64-efi --efi-directory=/boot/efi --removable
    update-grub
'

echo "[9/10] Building ISO..."
mkdir -p "$ISO_DIR"
mksquashfs "$CHROOT_DIR" "$ISO_DIR/filesystem.squashfs -comp xz
cp "$CHROOT_DIR/boot/vmlinuz-"* "$ISO_DIR/vmlinuz"
cp "$CHROOT_DIR/boot/initrd.img-"* "$ISO_DIR/initrd.img"

cat > "$ISO_DIR/isolinux.cfg" << 'ISOLINUX'
DEFAULT nexus
LABEL nexus
  MENU LABEL NEXUS OS
  KERNEL /vmlinuz
  APPEND initrd=/initrd.img root=/dev/ram0 rootfstype=squashfs quiet splash
ISOLINUX

xorriso -as mkisofs \
    -o "$OUTPUT_DIR/nexus-os.iso" \
    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
    -c isolinux/boot.cat \
    -b isolinux/isolinux.bin \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -eltorito-alt-boot \
    -e boot/grub/efi.img \
    -no-emul-boot \
    -isohybrid-gpt-basdat \
    "$ISO_DIR"

echo "[10/10] Done!"
echo "ISO saved to: $OUTPUT_DIR/nexus-os.iso"
