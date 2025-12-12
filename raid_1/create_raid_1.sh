#!/bin/bash
# create-raid1.sh
#
# Prepare two NVMe drives for an Ubuntu 22.04 RAID1 install:
#   - /dev/nvme0n1
#   - /dev/nvme1n1
#
# This will:
#   * STOP any existing mdadm arrays
#   * ERASE ALL DATA on both disks
#   * Create:
#       - 1 GiB EFI System partition on each disk
#       - RAID member partition using the remaining space on each disk
#   * Create /dev/md0 as a RAID1 array
#   * Format:
#       - /dev/md0 as ext4
#       - both EFI partitions as FAT32
#
# Run this from a Ubuntu Live environment (Ubuntu Desktop ISO Try OS) *before* running the server installer.

set -euo pipefail

DISK1="/dev/nvme0n1"
DISK2="/dev/nvme1n1"

echo "=== WARNING ==="
echo "This will ERASE ALL DATA on: ${DISK1} and ${DISK2}"
read -rp "Type 'YES' to continue: " CONFIRM
if [[ "${CONFIRM}" != "YES" ]]; then
  echo "Aborting."
  exit 1
fi

echo "=== Stopping any existing mdadm arrays ==="
mdadm --stop --scan || true

echo "=== Wiping RAID superblocks (if any) ==="
mdadm --zero-superblock "${DISK1}"* 2>/dev/null || true
mdadm --zero-superblock "${DISK2}"* 2>/dev/null || true

echo "=== Wiping partition tables and filesystem signatures ==="
wipefs -a "${DISK1}" || true
wipefs -a "${DISK2}" || true
sgdisk --zap-all "${DISK1}" || true
sgdisk --zap-all "${DISK2}" || true

echo "=== Creating new GPT on both disks ==="
sgdisk -og "${DISK1}"
sgdisk -og "${DISK2}"

echo "=== Creating partitions on ${DISK1} ==="
# Partition 1: 1 GiB EFI System (FAT32)
sgdisk -n1:0:+1G -t1:EF00 "${DISK1}"
# Partition 2: rest of disk for RAID
sgdisk -n2:0:0   -t2:FD00 "${DISK1}"

echo "=== Mirroring layout from ${DISK1} to ${DISK2} ==="
sgdisk -R="${DISK2}" "${DISK1}"
sgdisk -G "${DISK2}"  # new disk GUID

echo "=== Current partition tables ==="
sgdisk -p "${DISK1}"
sgdisk -p "${DISK2}"

PART1_DISK1="${DISK1}p1"
PART2_DISK1="${DISK1}p2"
PART1_DISK2="${DISK2}p1"
PART2_DISK2="${DISK2}p2"

echo "=== Creating RAID1 array /dev/md0 ==="
mdadm --create /dev/md0 \
  --level=1 \
  --raid-devices=2 \
  "${PART2_DISK1}" \
  "${PART2_DISK2}"

echo "Waiting a few seconds for md0 to assemble..."
sleep 3
cat /proc/mdstat || true

echo "=== Creating filesystems ==="
# Root filesystem on RAID
mkfs.ext4 -L root_raid1 /dev/md0

# EFI partitions (one active, one backup)
mkfs.vfat -F32 -n EFI1 "${PART1_DISK1}"
mkfs.vfat -F32 -n EFI2 "${PART1_DISK2}"

echo "=== Resulting block devices ==="
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT

echo
echo "RAID1 preparation complete."
echo "- Use /dev/md0 as root (/) during Ubuntu Server install."
echo "- Use ${PART1_DISK1} as EFI mounted at /boot/efi."
echo "- Leave ${PART1_DISK2} as an unmounted backup EFI."
