# NEXUS OS

NEXUS OS is an Ubuntu 24.04 live image with an XFCE desktop and a focused set of network, development, and security tools. The build creates a hybrid BIOS/UEFI ISO; it does not install to a disk or provide an installer — it is a live session image for testing and discovery.

## Build Locally

Requirements: Docker, at least 20 GB of free disk space, and 4 GB of memory for a VM.

From the repository root:

```sh
docker build -t nexus-os-builder ./custom-os-build
mkdir -p custom-os-build/output
docker run --rm --privileged \
	-v "$PWD/custom-os-build/output:/output" \
	nexus-os-builder
```

The ISO is written to `custom-os-build/output/nexus-os.iso`. The build container needs mount capabilities to configure a temporary chroot.

## Booting the ISO with QEMU (Ubuntu) — Copy & paste

Below are tested commands and the prerequisites for running the ISO on a Ubuntu host. Pick the command that matches whether you want a graphical window or a headless/serial run.

Prerequisites (install once):

```bash
sudo apt update
sudo apt install -y qemu-system-x86 qemu-kvm libvirt-daemon-system libvirt-clients 
# optional: virt-manager for a GUI, and spice/vnc packages if you prefer
sudo apt install -y virt-manager
# ensure your user can use KVM
sudo usermod -aG kvm "$USER"
# you may need to re-login for group changes to take effect
```

Graphical (recommended if your host supports KVM):

```bash
# boots the ISO in a window with KVM acceleration and network NAT with SSH forwarded to host:2222
qemu-system-x86_64 \
  -enable-kvm -machine accel=kvm \
  -m 4096 -smp 2 \
  -cdrom custom-os-build/output/nexus-os.iso \
  -boot d \
  -device e1000,netdev=net0 -netdev user,id=net0,hostfwd=tcp::2222-:22 \
  -vga virtio \
  -display gtk
```

Headless / Serial (useful for CI or when the host has no GUI):

```bash
# run headless, logging serial output to qemu.log (similar to the GitHub Actions workflow)
qemu-system-x86_64 \
  -machine accel=tcg \
  -m 4096 -smp 2 \
  -cdrom custom-os-build/output/nexus-os.iso \
  -boot d \
  -nographic \
  -no-reboot -no-shutdown > qemu.log 2>&1
# check the log for LightDM startup:
grep -q "Started Light Display Manager" qemu.log && echo "Graphical login started" || tail -n 200 qemu.log
```

Notes and troubleshooting:

- If you get a permission error opening /dev/kvm, ensure your kernel supports KVM and your user is in the kvm group. Check with `ls -l /dev/kvm` and `groups`.
- If `-enable-kvm` fails on your host (e.g., inside a nested VM or in some containers), use `-machine accel=tcg` instead (slower, software emulation).
- The `hostfwd` mapping above forwards host port 2222 to port 22 in the guest, so you can SSH into the live session (if sshd is active) with `ssh -p 2222 nexus@localhost`.
- Adjust memory (`-m`) and CPUs (`-smp`) based on your host capabilities.

## GitHub Actions

The `Build NEXUS OS ISO` workflow builds the image, boots it in QEMU through the graphical login (headless in CI), and uploads `nexus-os-iso` as a seven-day artifact. Start it from the repository's Actions tab or use repository_dispatch/workflow_dispatch.

## Live Session Tools

- `network-monitor` runs the included network checks.
- `nexus-hardening` applies system hardening and should only be run after reviewing its system-wide changes.
- `tor-routing` configures Tor services; it does not run automatically in the live session.

This image is for authorized security testing and education. The ISO has a live session and is not an installer.
