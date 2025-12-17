#!/usr/bin/env bash
set -Eeuo pipefail

echo "=== RTX 3060 Passthrough Helper Script ==="
echo ""

############################################
# STEP 1 — Detect RTX 3060 GPU + Audio
############################################
echo "[1] Detecting RTX 3060 GPU and audio function..."

GPU=$(lspci -nn | grep -i "NVIDIA" | grep "VGA" | awk '{print $1}')
AUDIO=$(lspci -nn | grep -i "NVIDIA" | grep "Audio" | awk '{print $1}')

if [[ -z "$GPU" || -z "$AUDIO" ]]; then
    echo "ERROR: Could not automatically detect NVIDIA GPU + Audio pair."
    echo "Ensure the RTX 3060 is installed and visible to the host."
    exit 1
fi

echo "GPU Device:   $GPU"
echo "Audio Device: $AUDIO"

############################################
# STEP 2 — Configure VFIO binding (persistent)
############################################
echo ""
echo "[2] Configuring VFIO PCI binding for RTX 3060..."

# RTX 3060 PCI IDs (confirmed earlier)
# GPU:   10de:2487
# Audio: 10de:228b
sudo tee /etc/modprobe.d/vfio.conf >/dev/null <<EOF
# Bind RTX 3060 GPU + Audio to vfio-pci for passthrough
options vfio-pci ids=10de:2487,10de:228b disable_vga=1
EOF

echo "VFIO configuration written to /etc/modprobe.d/vfio.conf"

############################################
# STEP 3 — Blacklist host GPU / framebuffer drivers
############################################
echo ""
echo "[3] Blacklisting host NVIDIA / framebuffer drivers..."

sudo tee /etc/modprobe.d/blacklist-nvidia.conf >/dev/null <<EOF
# Prevent host from binding RTX 3060
blacklist nouveau
blacklist nvidia
blacklist nvidiafb
blacklist rivafb
blacklist vesafb
blacklist efifb
EOF

echo "Blacklist written to /etc/modprobe.d/blacklist-nvidia.conf"

############################################
# STEP 4 — Ensure VFIO modules load early
############################################
echo ""
echo "[4] Ensuring VFIO modules load at boot..."

sudo tee /etc/modules-load.d/vfio.conf >/dev/null <<EOF
vfio
vfio_pci
vfio_iommu_type1
EOF

echo "VFIO modules load configuration written to /etc/modules-load.d/vfio.conf"

############################################
# STEP 5 — Rebuild initramfs (required)
############################################
echo ""
echo "[5] Rebuilding initramfs (this is required)..."

sudo update-initramfs -u -k all

echo ""
echo "=== IMPORTANT ==="
echo "A host reboot is REQUIRED for changes to take effect."
echo ""
echo "After reboot, verify with:"
echo "  lspci -nnk -s $GPU"
echo "  lspci -nnk -s $AUDIO"
echo ""
echo "Both must show: Kernel driver in use: vfio-pci"
echo ""
echo "=== Instructions for virt-manager (after reboot) ==="
echo "1. Open virt-manager"
echo "2. Select your gaming VM (gpu-3060-gaming)"
echo "3. Ensure VM is OFF"
echo "4. Add BOTH PCI devices:"
echo "     - $GPU (NVIDIA RTX 3060 GPU)"
echo "     - $AUDIO (NVIDIA HDMI Audio)"
echo "5. Remove Video Virtio"
echo "6. Set Display → None"
echo "7. Boot VM with monitor connected to RTX 3060"
echo ""
echo "Done."
