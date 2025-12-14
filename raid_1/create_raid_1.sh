#!/usr/bin/env bash
set -Eeuo pipefail

#############################################
# RAID-1 NVMe Setup Script (Ubuntu Live ISO)
# - Detects exactly two NVMe drives
# - Wipes all metadata
# - Creates EFI + RAID partitions
# - Builds mdadm RAID-1 array
#############################################

if [[ $EUID -ne 0 ]]; then
  echo "ERROR: Run this script as root (sudo)."
  exit 1
fi

echo "=== RAID-1 NVMe Setup (DESTRUCTIVE) ==="
echo "This will ERASE all data on BOTH NVMe drives."
echo
read -rp "Type 'YES' to continue: " CONFIRM
if [[ "$CONFIRM" != "YES" ]]; then
  echo "Aborted."
  exit 1
fi

echo
echo "[1] Detecting NVMe drives..."

mapfile -t NVME_DISKS < <(lsblk -ndo NAME,TYPE | awk '$2=="disk" && $1 ~ /^nvme/ {print "/dev/"$1}')

if [[ ${#NVME_DISKS[@]} -ne 2 ]]; then
  echo "ERROR: Expected exactly 2 NVMe disks, found ${#NVME_DISKS[@]}."
  printf 'Found: %s\n' "${NVME_DISKS[@]}"
  exit 1
fi

DISK1="${NVME_DISKS[0]}"
DISK2="${NVME_DISKS[1]}"

echo "Detected NVMe disks:"
echo "  $DISK1"
echo "  $DISK2"

echo
echo "[2] Stopping any existing RAID arrays..."
mdadm --stop --scan || true

echo
echo "[3] Wiping filesystem, RAID, and partition metadata..."

for d in "$DISK1" "$DISK2"; do
  echo "Wiping $d..."
  wipefs -a "$d"
  mdadm --zero-superblock --force "${d}"* || true
  sgdisk --zap-all "$d"
  dd if=/dev/zero of="$d" bs=1M count=10 status=none
done

echo
echo "[4] Creating GPT partition tables..."

for d in "$DISK1" "$DISK2"; do
  echo "Partitioning $d..."
  sgdisk \
    -n 1:0:+1G    -t 1:ef00 -c 1:"EFI System" \
    -n 2:0:0      -t 2:fd00 -c 2:"Linux RAID" \
    "$d"
done

echo
echo "[5] Informing kernel of partition changes..."
partprobe
sleep 2

EFI1="${DISK1}p1"
EFI2="${DISK2}p1"
RAID1="${DISK1}p2"
RAID2="${DISK2}p2"

echo
echo "[6] Creating RAID-1 array (/dev/md0)..."

mdadm --create /dev/md0 \
  --level=1 \
  --raid-devices=2 \
  "$RAID1" "$RAID2"

echo
echo "[7] Waiting for RAID device..."
udevadm settle
sleep 2

echo
echo "[8] Formatting RAID filesystem (ext4)..."
mkfs.ext4 -F /dev/md0

echo
echo "[9] Creating EFI filesystems..."
mkfs.vfat -F32 "$EFI1"
mkfs.vfat -F32 "$EFI2"

echo
echo "=== RAID-1 SETUP COMPLETE ==="
echo
echo "Created:"
echo "  EFI partitions: $EFI1 , $EFI2"
echo "  RAID device:    /dev/md0"
echo
echo "You may now:"
echo "  - Launch the Ubuntu installer"
echo "  - Mount /dev/md0 as / (root)"
echo "  - Use either EFI partition as /boot/efi"
echo
echo "NOTE: After install, ensure mdadm is installed and initramfs updated."
