# Running NEXUS OS (troubleshooting & VirtualBox notes)

This document explains how to run the NEXUS OS ISO and what to do if VT-x/AMD-V is unavailable (VirtualBox error VERR_VMX_MSR_ALL_VMX_DISABLED).

## Recommended: run with QEMU (script)

We added a convenience script at `tools/run-iso.sh` that will automatically use KVM when available or fall back to QEMU's software TCG emulator when hardware virtualization is disabled.

Usage:

```sh
# from repository root
chmod +x tools/run-iso.sh
./tools/run-iso.sh custom-os-build/output/nexus-os.iso
```

Options:
- Set MEM and CPUS environment variables to change memory/CPU allocation, e.g.
  `MEM=8192 CPUS=4 ./tools/run-iso.sh`
- If you have a desktop and a DISPLAY, the script will use a GUI display; otherwise it uses a serial console (`-nographic`).

## If you want VirtualBox (recommended to enable VT-x)

The VirtualBox error `VERR_VMX_MSR_ALL_VMX_DISABLED` means VT-x/AMD-V is disabled in your firmware or reserved by another kernel module.

On Ubuntu hosts:

1) Confirm your CPU supports virtualization:

```sh
lscpu | grep -i Virtualization
egrep -o 'vmx|svm' /proc/cpuinfo | sort -u
```

2) If those report nothing, enable virtualization in your BIOS/UEFI (Intel: "Intel Virtualization Technology" / "VT-x" / "Vanderpool". AMD: "SVM" / "AMD-V"). Reboot and retry.

3) If CPU flags show support but VirtualBox still fails, another hypervisor may be holding VT-x (KVM/qemu/libvirt). To free it temporarily:

```sh
# stop libvirt if running
sudo systemctl stop libvirtd virtlogd || true
# unload KVM modules (Intel/AMD as appropriate)
sudo rmmod kvm_intel kvm_amd kvm || sudo rmmod kvm_intel kvm || true
# re-run VirtualBox VM
```

To re-enable KVM later:

```sh
sudo modprobe kvm_intel   # or kvm_amd
sudo systemctl start libvirtd virtlogd
```

4) If VirtualBox kernel modules are broken (Secure Boot), recompile and (optionally) sign them:

```sh
sudo /sbin/vboxconfig
# or if distro packages
sudo dpkg-reconfigure virtualbox-dkms
```

If Secure Boot rejects unsigned modules, you can disable Secure Boot in firmware or sign the modules and enroll the key.

## Quick fallback (no VT-x available)

If you cannot enable VT-x, use the script above (it will use software emulation). Example manual QEMU command:

```sh
qemu-system-x86_64 -machine accel=tcg -m 4096 -smp 2 -cdrom custom-os-build/output/nexus-os.iso -boot d -display gtk
```

This will boot the ISO but performance will be significantly slower than with KVM.

## Performance / "lag-free" goals

Making a truly "lag-free" OS across every host is impossible to guarantee, but we can take steps to reduce latency and resource usage:

- Keep the desktop lightweight (XFCE is already chosen).
- Disable unnecessary services in the live session by default (e.g., auditd, rsyslog, heavy network scanning tools).
- Apply kernel tuning: reduce scheduling latency, enable PREEMPT_NONE or PREEMPT on low-latency kernels as appropriate.
- Provide a tuned profile (sysctl settings, tuned/latency profile) that users can opt into.

If you want, I can open PRs on the `fix-casper-live-root` branch to:
- Add this `tools/run-iso.sh` script and docs (done in this branch).
- Add a `tools/qemu-tcg-workflow.yml` GitHub Actions job that tests the ISO using TCG (so CI can verify builds on runners without KVM).
- Add a minimal performance tuning profile and an optional `nexus-perf` systemd target to enable low-latency settings.

Which of these would you like me to implement next?