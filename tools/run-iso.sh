#!/usr/bin/env bash
set -euo pipefail

# run-iso.sh - Run the built NEXUS OS ISO using the best available emulator.
# - Uses KVM accel when available for best performance.
# - Falls back to QEMU TCG (software) if hardware virtualization is unavailable.
# Usage: ./tools/run-iso.sh [path/to/nexus-os.iso]

ISO_PATH="${1:-custom-os-build/output/nexus-os.iso}"
MEM="${MEM:-4096}"
CPUS="${CPUS:-2}"

if [ ! -f "$ISO_PATH" ]; then
  echo "ERROR: ISO not found at $ISO_PATH"
  exit 2
fi

# detect CPU virtualization support
cpu_flags="$(egrep -o 'vmx|svm' /proc/cpuinfo | sort -u || true)"
has_vtx=false
if [ -n "$cpu_flags" ]; then
  has_vtx=true
fi

# detect /dev/kvm
if [ -e /dev/kvm ] && $has_vtx; then
  echo "KVM device available: using accel=kvm (best performance)"
  ACCEL="kvm"
else
  echo "Hardware virtualization (VT-x/AMD-V) not available or /dev/kvm missing."
  echo "Falling back to software emulation (accel=tcg). This will be slower."
  ACCEL="tcg"
fi

# choose display mode: if a DISPLAY is present attempt GUI, otherwise serial
if [ -n "${DISPLAY:-}" ]; then
  DISPLAY_OPTS="-display gtk"
else
  DISPLAY_OPTS="-nographic"
fi

echo "Running: qemu-system-x86_64 -machine accel=$ACCEL -m $MEM -smp $CPUS -cdrom $ISO_PATH -boot d $DISPLAY_OPTS"

# Keep SSH forwarding and audio off by default; user can customize below
qemu-system-x86_64 \
  -machine accel=$ACCEL \
  -m "$MEM" \
  -smp "$CPUS" \
  -cdrom "$ISO_PATH" \
  -boot d \
  $DISPLAY_OPTS
