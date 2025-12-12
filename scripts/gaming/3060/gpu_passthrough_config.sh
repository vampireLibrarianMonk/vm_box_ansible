#!/usr/bin/env bash
set -Eeuo pipefail

echo "=== RTX 3060 Passthrough Helper Script ==="

echo "[1] Checking IOMMU status..."
if ! dmesg | grep -qi "IOMMU enabled"; then
    echo "WARNING: IOMMU may not be enabled. Ensure GRUB has:"
    echo "    amd_iommu=on iommu=pt"
else
    echo "IOMMU detected."
fi

echo ""
echo "[2] Detecting RTX 3060 GPU and audio function..."

GPU=$(lspci -nn | grep -i "NVIDIA" | grep "VGA" | awk '{print $1}')
AUDIO=$(lspci -nn | grep -i "NVIDIA" | grep "Audio" | awk '{print $1}')

if [[ -z "$GPU" || -z "$AUDIO" ]]; then
    echo "ERROR: Could not automatically detect GPU + Audio pair."
    exit 1
fi

echo "GPU Device:   $GPU"
echo "Audio Device: $AUDIO"

echo ""
echo "=== Instructions for virt-manager ==="
echo "1. Open virt-manager"
echo "2. Select your gaming VM (gpu-3060-gaming)"
echo "3. Shut down the VM if running"
echo "4. Open 'Add Hardware' → 'PCI Host Device'"
echo "5. Add BOTH devices:"
echo "     - $GPU (NVIDIA RTX 3060 GPU)"
echo "     - $AUDIO (NVIDIA HDMI Audio)"
echo "6. Remove the existing virtual GPU:"
echo "     - Go to 'Video' → Remove"
echo "7. Go to 'Display' → Set: None"
echo "8. Boot VM on a monitor attached to the 3060"
echo ""
echo "Inside the VM, run in-guest script and install NVIDIA drivers."
echo "Done."
