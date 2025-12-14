#!/usr/bin/env bash
set -Eeuo pipefail

echo "=============================="
echo " AMD iGPU + Kernel Diagnostics"
echo "=============================="
echo

###############################################################################
# 1. Kernel Version (LOCAL)
#    - amdgpu console takeover bugs exist in older kernels (e.g., 5.15)
#    - VGACON ↔ amdgpu race can cause black screen during boot
#    - Kernel >= 6.1 mitigates this issue
#    - Kernel >= 6.5 (Ubuntu HWE) fully resolves it
#
#    If NOT upgraded:
#      - amdgpu may fail to initialize
#      - EFI framebuffer may be lost
#      - System may boot "blind" (black screen, SSH works)
###############################################################################

KERNEL="$(uname -r)"
echo "[KERNEL] Running kernel: $KERNEL"

KERNEL_MAJOR="$(echo "$KERNEL" | cut -d. -f1)"
KERNEL_MINOR="$(echo "$KERNEL" | cut -d. -f2)"

if (( KERNEL_MAJOR > 6 || (KERNEL_MAJOR == 6 && KERNEL_MINOR >= 1) )); then
  echo "[PASS] Kernel is new enough for stable AMD iGPU initialization"
else
  echo "[FAIL] Kernel too old — amdgpu may fail with black screen"
  echo
  echo "       REQUIRED ACTION:"
  echo "       Install Ubuntu HWE kernel (6.5+) with:"
  echo "         sudo apt update"
  echo "         sudo apt install --install-recommends linux-generic-hwe-22.04"
  echo
  echo "       Then reboot:"
  echo "         sudo reboot"
  echo
  echo "       Alternative (long-term): Upgrade to Ubuntu 24.04 LTS"
fi
echo

###############################################################################
# 2. amdgpu Kernel Module
#    - Confirms driver is loaded (not using fallback VGA/EFI only)
###############################################################################
echo "[CHECK] amdgpu kernel module loaded?"
if lsmod | grep -q "^amdgpu"; then
  echo "[PASS] amdgpu module is loaded"
else
  echo "[FAIL] amdgpu module NOT loaded"
  echo "       System likely running in EFI framebuffer or nomodeset"
fi
echo

###############################################################################
# 3. PCI Binding (Driver-in-use MUST be amdgpu)
###############################################################################
echo "[CHECK] PCI device binding:"
lspci -nnk | awk '
/VGA compatible controller/ {v=1}
v {print}
v && /Kernel driver in use/ {v=0}
'
echo

###############################################################################
# 4. DRM Devices (KMS must exist)
#    - cardX + renderD128 indicate working kernel modesetting
###############################################################################
echo "[CHECK] DRM devices:"
ls /sys/class/drm/ || true
echo

if ls /sys/class/drm/ | grep -q "renderD"; then
  echo "[PASS] DRM render node present (KMS active)"
else
  echo "[FAIL] No DRM render node — GPU acceleration unavailable"
fi
echo

###############################################################################
# 5. dmesg Validation (CONFIRM CLEAN INIT)
#    - fbcon should bind to amdgpudrmfb
###############################################################################
echo "[CHECK] amdgpu initialization (last lines):"
dmesg | grep -i amdgpu | tail -15
echo

if dmesg | grep -qi "Initialized amdgpu"; then
  echo "[PASS] amdgpu initialized successfully"
else
  echo "[FAIL] amdgpu did not initialize cleanly"
fi
echo

###############################################################################
# 6. ONLINE KERNEL CONTEXT (DOCUMENTATION-ONLY)
#    - We do NOT auto-upgrade here
#    - This explains WHY updates matter
###############################################################################
echo "[INFO] Kernel support context (documentation):"
cat <<'EOF'
- Ubuntu 22.04 default kernel: 5.15
  ❌ Known amdgpu + VGACON race → black screen on RAID / UEFI systems

- Ubuntu 22.04 HWE kernel: 6.5+
  ✅ Fixes console handoff ordering
  ✅ Stable AMD iGPU initialization

- Ubuntu 24.04 kernel: 6.8+
  ✅ Cleanest amdgpu behavior
  ✅ What this system is running now

If kernel is NOT updated:
- amdgpu may fail during early boot
- EFI framebuffer disabled → black screen
- System boots "blind" (network works, no display)
EOF

echo
echo "=============================="
echo " Diagnostic complete"
echo "=============================="
