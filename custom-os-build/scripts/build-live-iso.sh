#!/usr/bin/env bash
set -Eeuo pipefail

BUILD_DIR="${BUILD_DIR:-/build}"
OUTPUT_DIR="${OUTPUT_DIR:-/output}"
CHROOT_DIR="$BUILD_DIR/chroot"
ISO_DIR="$BUILD_DIR/iso"

mkdir -p "$BUILD_DIR" "$OUTPUT_DIR"
rm -rf "$CHROOT_DIR" "$ISO_DIR"
mkdir -p "$CHROOT_DIR" "$ISO_DIR/casper" "$ISO_DIR/boot/grub"

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
        linux-generic linux-firmware \
        casper systemd-sysv systemd-resolved network-manager net-tools iproute2 kmod procps sudo \
        vim-tiny nano curl wget git \
        xserver-xorg xserver-xorg-video-all xserver-xorg-input-all \
        lightdm lightdm-gtk-greeter xfce4 xfce4-goodies xfce4-terminal dbus-x11 plymouth \
        greybird-gtk-theme elementary-xfce-icon-theme fonts-dejavu-core \
        epiphany-browser synaptic policykit-1-gnome \
        pulseaudio alsa-utils openssh-server ufw apparmor apparmor-utils \
        auditd rsyslog chrony tor torsocks netcat-openbsd lsof less unattended-upgrades \
        nmap sqlmap aircrack-ng wireshark tcpdump john hashcat binwalk \
        strace ltrace gdb zsh fish tmux fzf ripgrep fd-find bat btop htop jq \
        python3 python3-pip python3-venv nodejs npm golang-go openjdk-17-jdk \
        ruby perl php lua5.4 lynis firejail
    apt-get clean
'
for app in epiphany synaptic-pkexec Xorg xfce4-session lightdm-gtk-greeter; do
    if ! chroot "$CHROOT_DIR" /usr/bin/env bash -ec "command -v '$app' >/dev/null"; then
        echo "Required desktop application is missing after package installation: $app" >&2
        exit 1
    fi
done
rm -f "$CHROOT_DIR/usr/sbin/policy-rc.d"
ln -sfn /run/systemd/resolve/stub-resolv.conf "$CHROOT_DIR/etc/resolv.conf"

echo "[4/7] Configuring live session..."
cat > "$CHROOT_DIR/etc/casper.conf" <<'CASPER'
export USERNAME="nexus"
export USERFULLNAME="NEXUS OS"
export HOST="nexus"
CASPER

mkdir -p "$CHROOT_DIR/etc/lightdm/lightdm.conf.d" "$CHROOT_DIR/usr/local/bin"
mkdir -p \
    "$CHROOT_DIR/usr/share/backgrounds/nexus" \
    "$CHROOT_DIR/usr/share/pixmaps" \
    "$CHROOT_DIR/usr/share/applications" \
    "$CHROOT_DIR/usr/share/nexus" \
    "$CHROOT_DIR/etc/skel/Desktop" \
    "$CHROOT_DIR/etc/skel/.config/xfce4/terminal" \
    "$CHROOT_DIR/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml" \
    "$CHROOT_DIR/etc/skel/.cache/zsh"
if [[ -x "$CHROOT_DIR/usr/bin/fdfind" ]]; then
    ln -sfn /usr/bin/fdfind "$CHROOT_DIR/usr/local/bin/fd"
fi
if [[ -x "$CHROOT_DIR/usr/bin/batcat" ]]; then
    ln -sfn /usr/bin/batcat "$CHROOT_DIR/usr/local/bin/bat"
fi
install -m 0644 "$(dirname "$0")/../assets/nexus-wallpaper.svg" \
    "$CHROOT_DIR/usr/share/backgrounds/nexus/nexus-wallpaper.svg"
install -m 0644 "$(dirname "$0")/../assets/nexus-logo.svg" \
    "$CHROOT_DIR/usr/share/pixmaps/nexus-logo.svg"
cat > "$CHROOT_DIR/usr/share/applications/nexus-settings.desktop" <<'DESKTOP'
[Desktop Entry]
Version=1.0
Type=Application
Name=NEXUS OS Settings
Comment=Ubuntu-based NEXUS live workstation
Exec=xfce4-settings-manager
Icon=/usr/share/pixmaps/nexus-logo.svg
Terminal=false
Categories=System;Settings;
DESKTOP
install -m 0644 "$CHROOT_DIR/usr/share/applications/nexus-settings.desktop" \
    "$CHROOT_DIR/etc/skel/Desktop/NEXUS OS Settings.desktop"
cat > "$CHROOT_DIR/usr/share/applications/nexus-app-catalogs.desktop" <<'DESKTOP'
[Desktop Entry]
Version=1.0
Type=Application
Name=NEXUS App Catalogs
Comment=Browse official app catalogs and Ubuntu software
Exec=epiphany file:///usr/share/nexus/app-catalogs.html
Icon=web-browser
Terminal=false
Categories=Network;WebBrowser;
DESKTOP
install -m 0755 "$CHROOT_DIR/usr/share/applications/nexus-app-catalogs.desktop" \
    "$CHROOT_DIR/etc/skel/Desktop/NEXUS App Catalogs.desktop"
cat > "$CHROOT_DIR/usr/share/nexus/app-catalogs.html" <<'CATALOGS'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>NEXUS App Catalogs</title>
  <style>
    :root { color-scheme: dark; font: 16px/1.55 system-ui, sans-serif; background: #121922; color: #e8edf4; }
    body { max-width: 920px; margin: 0 auto; padding: 42px 24px; }
    h1 { font-size: 2rem; font-weight: 550; letter-spacing: .08em; }
    p { color: #b7c1ce; }
    .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 14px; margin: 28px 0; }
    article { padding: 20px; border: 1px solid #374251; border-radius: 10px; background: #1b2430; }
    article h2 { margin-top: 0; font-size: 1.1rem; }
    a { color: #a9c7e8; }
    .note { padding: 16px; border-left: 3px solid #829bb8; background: #1b2430; }
  </style>
</head>
<body>
  <h1>NEXUS App Catalogs</h1>
  <p>Open the official catalogs in this browser. These links let you browse their websites; they do not install mobile or Windows applications on NEXUS OS.</p>
  <div class="grid">
    <article><h2>Google Play</h2><p>Android apps and games. Installing Android apps requires a compatible Android device.</p><a href="https://play.google.com/store">Browse Google Play</a></article>
    <article><h2>Apple App Store</h2><p>Apps for Apple devices. The App Store client and iOS apps are not available for Ubuntu.</p><a href="https://www.apple.com/app-store/">Browse the App Store</a></article>
    <article><h2>Microsoft Store</h2><p>Windows apps and games. Windows Store apps do not install as native Ubuntu applications.</p><a href="https://apps.microsoft.com/">Browse Microsoft Store</a></article>
  </div>
  <aside class="note"><strong>Install native Ubuntu software:</strong> open Synaptic Package Manager from the Applications menu, or use <code>sudo apt install package-name</code> in Terminal. Review a package and its source before installing it.</aside>
</body>
</html>
CATALOGS
cat > "$CHROOT_DIR/usr/share/applications/nexus-synaptic.desktop" <<'DESKTOP'
[Desktop Entry]
Version=1.0
Type=Application
Name=NEXUS Software Manager
Comment=Install and manage Ubuntu packages
Exec=synaptic-pkexec
Icon=synaptic
Terminal=false
Categories=System;PackageManager;
DESKTOP
install -m 0755 "$CHROOT_DIR/usr/share/applications/nexus-synaptic.desktop" \
    "$CHROOT_DIR/etc/skel/Desktop/NEXUS Software Manager.desktop"

cat > "$CHROOT_DIR/etc/lightdm/lightdm.conf.d/50-nexus-autologin.conf" <<'LIGHTDM'
[Seat:*]
autologin-user=nexus
autologin-user-timeout=0
greeter-session=lightdm-gtk-greeter
LIGHTDM

cat > "$CHROOT_DIR/usr/local/sbin/nexus-boot-diagnostics" <<'DIAGNOSTICS'
#!/usr/bin/env bash
echo "=== NEXUS graphical boot diagnostics ==="
systemctl --no-pager --full status lightdm.service || true
journalctl -b --no-pager -u lightdm.service -n 80 || true
for log in /var/log/lightdm/lightdm.log /var/log/lightdm/x-0.log /var/log/Xorg.0.log; do
    if [[ -f "$log" ]]; then
        echo "=== $log ==="
        tail -n 100 "$log"
    fi
done
echo "=== End NEXUS graphical boot diagnostics ==="
DIAGNOSTICS
chmod 0755 "$CHROOT_DIR/usr/local/sbin/nexus-boot-diagnostics"
cat > "$CHROOT_DIR/etc/systemd/system/nexus-boot-diagnostics.service" <<'DIAGNOSTICS_SERVICE'
[Unit]
Description=Print graphical boot diagnostics to the serial console

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/nexus-boot-diagnostics
StandardOutput=tty
StandardError=tty
TTYPath=/dev/ttyS0
TTYReset=no
TTYVHangup=no
TTYVTDisallocate=no
DIAGNOSTICS_SERVICE
cat > "$CHROOT_DIR/etc/systemd/system/nexus-boot-diagnostics.timer" <<'DIAGNOSTICS_TIMER'
[Unit]
Description=Collect graphical boot diagnostics after startup

[Timer]
OnBootSec=90s
AccuracySec=1s
Unit=nexus-boot-diagnostics.service

[Install]
WantedBy=timers.target
DIAGNOSTICS_TIMER

install -m 0755 "$(dirname "$0")/network-monitor.sh" "$CHROOT_DIR/usr/local/bin/network-monitor"
install -m 0755 "$(dirname "$0")/security-hardening.sh" "$CHROOT_DIR/usr/local/bin/nexus-hardening"
install -m 0755 "$(dirname "$0")/tor-routing.sh" "$CHROOT_DIR/usr/local/bin/tor-routing"

cat > "$CHROOT_DIR/etc/skel/.zshrc" <<'ZSHRC'
autoload -Uz colors vcs_info
colors
autoload -Uz compinit
compinit -d "$HOME/.cache/zsh/zcompdump"
zstyle ':completion:*' menu select
zstyle ':vcs_info:git:*' formats ' (%F{blue}%b%f)'
precmd() { vcs_info }
setopt PROMPT_SUBST
PROMPT='%F{green}%n%f@%F{cyan}%m%f %F{blue}%~%f${vcs_info_msg_0_}
%F{magenta}>%f '
RPROMPT='%F{242}%*%f'
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS HIST_FCNTL_LOCK SHARE_HISTORY
alias ll='ls -alF --color=auto'
alias la='ls -A --color=auto'
alias grep='grep --color=auto'
alias update='sudo apt update && sudo apt upgrade'
alias tor-ip='sudo tor-change-ip'
export EDITOR=nano
export PAGER='less -FR'
export TERM=xterm-256color
ZSHRC

if grep -q '^DSHELL=' "$CHROOT_DIR/etc/adduser.conf"; then
    sed -i 's|^DSHELL=.*|DSHELL=/usr/bin/zsh|' "$CHROOT_DIR/etc/adduser.conf"
else
    printf '\nDSHELL=/usr/bin/zsh\n' >> "$CHROOT_DIR/etc/adduser.conf"
fi

cat > "$CHROOT_DIR/etc/skel/.config/xfce4/terminal/terminalrc" <<'TERMINAL'
[Configuration]
FontName=DejaVu Sans Mono 11
ColorForeground=#d5deea
ColorBackground=#10151d
ColorPalette=#202733;#df6c75;#8bbf9f;#d3b779;#85a9d6;#b09acb;#7cb9bd;#c7d0da;#687587;#f0838d;#a1d3b2;#ead08e;#9bbbe2;#c4addc;#91cdd0;#f2f5f8
ColorCursor=#b8c9dc
ColorCursorForeground=#10151d
MiscAudibleBell=FALSE
MiscCursorBlinks=FALSE
MiscCursorShape=TERMINAL_CURSOR_SHAPE_BLOCK
MiscMenubarDefault=FALSE
MiscToolbarDefault=FALSE
TERMINAL

cat > "$CHROOT_DIR/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml" <<'XFCE_DESKTOP'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitor0" type="empty">
        <property name="workspace0" type="empty">
          <property name="last-image" type="string" value="/usr/share/backgrounds/nexus/nexus-wallpaper.svg"/>
          <property name="image-path" type="string" value="/usr/share/backgrounds/nexus/nexus-wallpaper.svg"/>
          <property name="image-style" type="int" value="5"/>
          <property name="color-style" type="int" value="0"/>
        </property>
      </property>
    </property>
  </property>
</channel>
XFCE_DESKTOP

cat > "$CHROOT_DIR/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" <<'XFCE_SETTINGS'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="Greybird-dark"/>
    <property name="IconThemeName" type="string" value="elementary-xfce-dark"/>
  </property>
</channel>
XFCE_SETTINGS

systemctl --root="$CHROOT_DIR" enable \
    lightdm.service NetworkManager.service systemd-resolved.service \
    apt-daily.timer apt-daily-upgrade.timer nexus-boot-diagnostics.timer

echo "[5/7] Preparing live boot files..."
kernel=$(find "$CHROOT_DIR/boot" -maxdepth 1 -type f -name 'vmlinuz-*' -print | sort -V | tail -n 1)
initrd=$(find "$CHROOT_DIR/boot" -maxdepth 1 -type f -name 'initrd.img-*' -print | sort -V | tail -n 1)
if [[ -z "$kernel" || -z "$initrd" ]]; then
    echo "Kernel or initrd was not installed" >&2
    exit 1
fi
cp "$kernel" "$ISO_DIR/casper/vmlinuz"
cp "$initrd" "$ISO_DIR/casper/initrd"

cleanup_mounts
mksquashfs "$CHROOT_DIR" "$ISO_DIR/casper/filesystem.squashfs" -comp xz -noappend
du -sx --block-size=1 "$CHROOT_DIR" | cut -f1 > "$ISO_DIR/casper/filesystem.size"

cat > "$ISO_DIR/boot/grub/grub.cfg" <<'GRUB'
set menu_color_normal=light-gray/black
set menu_color_highlight=white/blue
set color_normal=light-gray/black
set color_highlight=white/blue
serial --unit=0 --speed=115200
terminal_input console serial
terminal_output console serial
set timeout=8
set default=0

menuentry "NEXUS OS  |  Start live desktop" {
    linux /casper/vmlinuz boot=casper username=nexus hostname=nexus console=tty0 console=ttyS0,115200n8 systemd.show_status=1 ---
    initrd /casper/initrd
}

menuentry "NEXUS OS  |  Start in safe graphics mode" {
    linux /casper/vmlinuz boot=casper username=nexus hostname=nexus nomodeset console=tty0 console=ttyS0,115200n8 systemd.show_status=1 ---
    initrd /casper/initrd
}
GRUB

echo "[6/7] Building hybrid BIOS/UEFI ISO..."
grub-mkrescue -o "$OUTPUT_DIR/nexus-os.iso" "$ISO_DIR"
test -s "$OUTPUT_DIR/nexus-os.iso"

echo "[7/7] Build complete: $OUTPUT_DIR/nexus-os.iso"