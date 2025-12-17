#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $EUID -eq 0 ]]; then
  echo "Do not run this script as root. Run as your normal user."
  exit 1
fi

###############################################################################
# Shared Game Data Disk Setup Script (libvirt-safe)
#
# Usage:
#   bash scripts/game_disk_setup.sh <DISK_SIZE>
#
# Example:
#   bash scripts/game_disk_setup.sh 120G
#
# Result:
#   /var/lib/libvirt/images/game-data.qcow2
#
###############################################################################

show_help() {
    echo "Usage: $0 <DISK_SIZE>"
    echo ""
    echo "Example:"
    echo "  $0 100G"
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

# Staging location (user-writable)
STAGING_DIR="$HOME/vms"
STAGING_DISK="$STAGING_DIR/game-data.qcow2"

# Final libvirt-safe location
LIBVIRT_DIR="/var/lib/libvirt/images"
FINAL_DISK="$LIBVIRT_DIR/game-data.qcow2"

echo "=== Shared Game Data Disk Setup (libvirt-safe) ==="
echo "Disk size:            $DISK_SIZE"
echo "Staging directory:    $STAGING_DIR"
echo "Final destination:   $FINAL_DISK"
echo ""

############################################
# STEP 1 — Ensure staging directory exists
############################################
echo "[1] Ensuring staging directory exists..."
mkdir -p "$STAGING_DIR"

if [[ ! -w "$STAGING_DIR" ]]; then
    echo "ERROR: $STAGING_DIR is not writable by user $(whoami)"
    exit 1
fi

############################################
# STEP 2 — Check qemu-img availability
############################################
echo "[2] Checking qemu-img availability..."
if ! command -v qemu-img >/dev/null 2>&1; then
    echo "ERROR: qemu-img not found. Install with:"
    echo "  sudo apt install -y qemu-utils"
    exit 1
fi

############################################
# STEP 3 — Create disk (if missing)
############################################
echo "[3] Creating or validating game data disk..."
if [[ ! -f "$STAGING_DISK" ]]; then
    echo "Creating $STAGING_DISK ($DISK_SIZE, thin provisioned)..."
    qemu-img create -f qcow2 "$STAGING_DISK" "$DISK_SIZE"
else
    echo "[SKIP] Disk already exists at: $STAGING_DISK"
fi

############################################
# STEP 4 — Move disk into libvirt storage
############################################
echo "[4] Installing disk into libvirt storage..."

if [[ ! -d "$LIBVIRT_DIR" ]]; then
    echo "ERROR: $LIBVIRT_DIR does not exist."
    echo "Is libvirt installed?"
    exit 1
fi

sudo mv "$STAGING_DISK" "$FINAL_DISK"

############################################
# STEP 5 — Fix ownership and permissions
############################################
echo "[5] Setting ownership and permissions..."

sudo chown libvirt-qemu:kvm "$FINAL_DISK"
sudo chmod 660 "$FINAL_DISK"

############################################
# DONE
############################################
echo ""
echo "=== Game Data Disk Setup Complete ==="
echo "Location: $FINAL_DISK"
echo ""
echo "Attach this disk to gaming VMs as a second virtio disk:"
echo "  target dev: vdb"
echo ""
echo "Inside the VM:"
echo "  sudo mkfs.ext4 /dev/vdb   # first time only"
echo "  sudo mkdir -p /mnt/games"
echo "  sudo mount /dev/vdb /mnt/games"
