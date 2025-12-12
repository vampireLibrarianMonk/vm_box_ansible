#!/usr/bin/env bash
set -Eeuo pipefail

###############################################################################
# Gaming VM Image Setup Script
#
# This script:
#   1. Creates a gaming OS qcow2 disk
#   2. Reuses the shared ~/vms/game-data.qcow2 disk
#   3. Defines a gaming VM prepared for RTX 3060 passthrough
#   4. Auto-generates in-guest setup instructions for mounting /mnt/games
#
# Usage:
#   ./gaming_vm_setup.sh <VM_NAME> <OS_DISK_SIZE> <ISO_PATH>
#
# Example:
#   ./gaming_vm_setup.sh gpu-3060-gaming 25G ~/isos/ubuntu-22.04.5.iso
###############################################################################

if [[ $# -lt 3 ]]; then
    echo "Usage: $0 <VM_NAME> <OS_DISK_SIZE> <ISO_PATH>"
    echo "Example: $0 gpu-3060-gaming 25G ~/isos/ubuntu.iso"
    exit 1
fi

VM_NAME="$1"
OS_SIZE="$2"
ISO_PATH="$3"

VMS_DIR="$HOME/vms"
OS_DISK="$VMS_DIR/${VM_NAME}.qcow2"
GAME_DISK="$VMS_DIR/game-data.qcow2"

echo "=== Gaming VM Image Setup ==="
echo "VM Name     : $VM_NAME"
echo "OS Disk     : $OS_DISK ($OS_SIZE)"
echo "ISO Path    : $ISO_PATH"
echo "Game Disk   : $GAME_DISK"
echo ""

# --------------------------------------------------------------------------- #
# 1. Ensure directories
# --------------------------------------------------------------------------- #
echo "[1] Ensuring VM directory exists..."
mkdir -p "$VMS_DIR"

# --------------------------------------------------------------------------- #
# 2. Validate ISO
# --------------------------------------------------------------------------- #
if [[ ! -f "$ISO_PATH" ]]; then
    echo "ERROR: ISO not found: $ISO_PATH"
    exit 1
fi

# --------------------------------------------------------------------------- #
# 3. Validate shared game disk
# --------------------------------------------------------------------------- #
if [[ ! -f "$GAME_DISK" ]]; then
    echo "ERROR: Shared game-data disk missing: $GAME_DISK"
    echo "Create it using your game-disk setup script."
    exit 1
fi

# --------------------------------------------------------------------------- #
# 4. Create OS disk
# --------------------------------------------------------------------------- #
if [[ -f "$OS_DISK" ]]; then
    echo "[SKIP] OS disk already exists: $OS_DISK"
else
    echo "[2] Creating OS disk ($OS_SIZE)..."
    qemu-img create -f qcow2 "$OS_DISK" "$OS_SIZE"
fi

# --------------------------------------------------------------------------- #
# 5. Create VM definition (virt-install)
#
# NOTE: This VM is created WITHOUT a GPU. You add RTX 3060 passthrough
#       via virt-manager or your VFIO automation after installation.
# --------------------------------------------------------------------------- #
echo "[3] Defining VM $VM_NAME with virt-install..."

sudo virt-install \
  --name "$VM_NAME" \
  --memory 16384 \
  --vcpus 8 \
  --cpu host-passthrough \
  --machine q35 \
  --boot uefi \
  --disk "path=$OS_DISK,format=qcow2,bus=virtio" \
  --disk "path=$GAME_DISK,format=qcow2,bus=virtio" \
  --os-variant ubuntu22.04 \
  --cdrom "$ISO_PATH" \
  --graphics spice \
  --video virtio \
  --network network=default \
  --noautoconsole || echo "[WARN] VM may already exist."

echo ""
echo "=== Next Step: Configure GPU Passthrough ==="
echo "Run the following helper script on the host:"
echo ""
echo "    bash gpu_passthrough_config.sh"
echo ""
echo "This script will:"
echo "  ✓ Detect RTX 3060 PCI device IDs"
echo "  ✓ Validate IOMMU status"
echo "  ✓ Output exact devices to add in virt-manager"
echo "  ✓ Provide precise VM edits for passthrough"
echo ""
echo "After running it, proceed with NVIDIA driver installation INSIDE the VM."
