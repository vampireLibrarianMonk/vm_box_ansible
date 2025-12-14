#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $EUID -eq 0 ]]; then
  echo "Do not run this script as root. Run as your normal user."
  exit 1
fi

###############################################################################
# Shared Game Data Disk Setup Script
# Usage:
#   bash scripts/game_disk_setup.sh <DISK_SIZE> [VMS_DIR]
#
# Example:
#   bash scripts/game_disk_setup.sh 120G
#   bash scripts/game_disk_setup.sh 150G /mnt/vmstore
#
# Arguments:
#   DISK_SIZE - required, qcow2 size (e.g., 100G, 120G, 200G)
#   VMS_DIR   - optional, root directory for VM storage (default: ~/vms)
###############################################################################

show_help() {
    echo "Usage: $0 <DISK_SIZE> [VMS_DIR]"
    echo ""
    echo "Example:"
    echo "  $0 100G"
    echo "  $0 150G /mnt/vmstore"
    exit 1
}

# Help flags
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    show_help
fi

# Argument validation
if [[ -z "${1:-}" ]]; then
    echo "ERROR: Missing required argument DISK_SIZE."
    show_help
fi

DISK_SIZE="$1"
VMS_DIR="${2:-$HOME/vms}"

GAME_DISK="$VMS_DIR/game-data.qcow2"

echo "=== Shared Game Data Disk Setup ==="
echo "Disk size: $DISK_SIZE"
echo "VM storage directory: $VMS_DIR"

echo "[1] Ensuring VM storage directory exists..."
mkdir -p "$VMS_DIR"

# Ensure directory is owned by the invoking user
if [[ ! -w "$VMS_DIR" ]]; then
    echo "ERROR: $VMS_DIR is not writable by user $(whoami)"
    echo "Fix with:"
    echo "  sudo chown -R $(whoami):$(whoami) $VMS_DIR"
    exit 1
fi

echo "[2] Checking qemu-img availability..."
if ! command -v qemu-img >/dev/null 2>&1; then
    echo "ERROR: qemu-img not found. Install qemu-utils or qemu-kvm package."
    exit 1
fi

echo "[3] Creating or validating game data disk..."
if [[ ! -f "$GAME_DISK" ]]; then
    echo "Creating $GAME_DISK ($DISK_SIZE, thin provisioned)..."
    qemu-img create -f qcow2 "$GAME_DISK" "$DISK_SIZE"
else
    echo "[SKIP] game-data.qcow2 already exists at: $GAME_DISK"
fi

echo "=== Game Data Disk Setup Complete ==="
echo "Location: $GAME_DISK"
echo ""
echo "Attach this disk to gaming VMs as a second virtio disk (vdb)."
echo "Inside the VM, mount to /mnt/games and update fstab accordingly."
