# NEXUS OS

NEXUS OS is an Ubuntu 24.04 live image with an XFCE desktop and a focused set of network, development, and security tools. The build creates a hybrid BIOS/UEFI ISO; it does not install to a disk or configure all system traffic to use Tor.

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

The ISO is written to `custom-os-build/output/nexus-os.iso`. The build container needs mount capabilities to configure a temporary chroot. The builder packages the ISO without installing GRUB to a host disk.

## GitHub Actions

The `Build NEXUS OS ISO` workflow builds the image, boots it in QEMU through the graphical login, and uploads `nexus-os-iso` as a seven-day artifact. Start it from the repository's Actions tab or with `workflow_dispatch`.

## Live Session Tools

- `network-monitor` runs the included network checks.
- `nexus-hardening` applies system hardening and should only be run after reviewing its system-wide changes.
- `tor-routing` configures Tor services; it does not run automatically in the live session.

This image is for authorized security testing and education. The ISO has a live session and is not an installer.
