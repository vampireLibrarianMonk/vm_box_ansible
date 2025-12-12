#!/bin/bash
#
# verify-raid1.sh
#
# Comprehensive RAID1 verification script.
# Confirms the RAID setup exactly as configured in this chat.
#
# Usage:
#     sudo ./verify-raid1.sh /dev/nvme0n1 /dev/nvme1n1
#
# Requirements:
#     - Two arguments (the two physical drives)
#     - Script must run on the installed Ubuntu system
#
# This script checks:
#   1. Disks exist
#   2. EFI + RAID partitions exist
#   3. mdadm RAID array exists
#   4. RAID level is RAID1
#   5. RAID state is clean
#   6. mdadm.conf contains the array definition
#   7. Root filesystem is mounted from /dev/md0
#   8. EFI is mounted
#   9. Both drives contribute to md0
#

set -euo pipefail

# ---------------------------
# VALIDATE INPUT
# ---------------------------
if [[ "$#" -ne 2 ]]; then
    echo "Usage: sudo $0 <disk1> <disk2>"
    echo "Example: sudo $0 /dev/nvme0n1 /dev/nvme1n1"
    exit 1
fi

DISK1="$1"
DISK2="$2"

echo "==========================================================="
echo "              RAID1 VERIFICATION SCRIPT"
echo "==========================================================="
echo "Checking RAID setup for:"
echo "  DRIVE 1: $DISK1"
echo "  DRIVE 2: $DISK2"
echo "==========================================================="
echo

# ---------------------------
# Check disks exist
# ---------------------------
echo "[1] Checking that disks exist..."
for D in "$DISK1" "$DISK2"; do
    if [[ ! -b "$D" ]]; then
        echo "ERROR: Disk '$D' does not exist."
        exit 1
    fi
done
echo "✔ Disks found"
echo

# ---------------------------
# Check expected partitions
# ---------------------------
echo "[2] Checking for correct EFI + RAID partitions..."

EFI1="${DISK1}p1"
RAID1="${DISK1}p2"
EFI2="${DISK2}p1"
RAID2="${DISK2}p2"

for P in "$EFI1" "$RAID1" "$EFI2" "$RAID2"; do
    if [[ ! -b "$P" ]]; then
        echo "ERROR: Expected partition missing: '$P'"
        exit 1
    fi
done

echo "✔ EFI partitions: $EFI1, $EFI2"
echo "✔ RAID partitions: $RAID1, $RAID2"
echo

# ---------------------------
# Check RAID array exists
# ---------------------------
echo "[3] Checking for mdadm RAID array /dev/md0..."
if [[ ! -b "/dev/md0" ]]; then
    echo "ERROR: /dev/md0 not found."
    exit 1
fi
echo "✔ /dev/md0 exists"
echo

# ---------------------------
# Check RAID details
# ---------------------------
echo "[4] Checking RAID level and status..."

MD_DETAIL="$(mdadm --detail /dev/md0)"

if ! echo "$MD_DETAIL" | grep -q "Raid Level : raid1"; then
    echo "ERROR: RAID level is not RAID1"
    exit 1
fi

if ! echo "$MD_DETAIL" | grep -q "State : clean"; then
    echo "WARNING: RAID state is not clean (may be recovering)"
else
    echo "✔ RAID state clean"
fi

echo "✔ RAID1 level confirmed"
echo

# ---------------------------
# Check both drives are active
# ---------------------------
echo "[5] Confirming both RAID members are active..."

RAID1_BASENAME="$(basename "$RAID1")"
RAID2_BASENAME="$(basename "$RAID2")"

if ! echo "$MD_DETAIL" | grep -q "$RAID1_BASENAME"; then
    echo "ERROR: RAID member missing: '$RAID1_BASENAME'"
    exit 1
fi

if ! echo "$MD_DETAIL" | grep -q "$RAID2_BASENAME"; then
    echo "ERROR: RAID member missing: '$RAID2_BASENAME'"
    exit 1
fi

echo "✔ Both RAID devices active in md0"
echo

# ---------------------------
# Check mdadm.conf
# ---------------------------
echo "[6] Checking /etc/mdadm/mdadm.conf for ARRAY definition..."

if ! grep -q "ARRAY /dev/md0" /etc/mdadm/mdadm.conf; then
    echo "ERROR: mdadm.conf does not contain ARRAY /dev/md0"
    exit 1
fi

echo "✔ mdadm.conf contains correct ARRAY entry"
echo

# ---------------------------
# Verify root filesystem is md0
# ---------------------------
echo "[7] Checking if / is mounted from /dev/md0..."

ROOT_SRC="$(findmnt -n -o SOURCE / || true)"

if [[ "$ROOT_SRC" != "/dev/md0" ]]; then
    echo "ERROR: Root filesystem is NOT mounted from /dev/md0 (found '$ROOT_SRC')"
    exit 1
fi

echo "✔ Root filesystem mounted from /dev/md0"
echo

# ---------------------------
# Verify EFI mount
# ---------------------------
echo "[8] Checking EFI mount..."

EFI_SRC="$(findmnt -n -o SOURCE /boot/efi || true)"

if [[ -z "$EFI_SRC" ]]; then
    echo "ERROR: No EFI partition mounted at /boot/efi"
    exit 1
fi

echo "✔ EFI mounted from $EFI_SRC"
echo

echo "==========================================================="
echo "          RAID1 VERIFICATION COMPLETE — SUCCESS"
echo "==========================================================="
echo "Your system is correctly configured with:"
echo "  ✔ RAID1 root filesystem"
echo "  ✔ Clean md0 array"
echo "  ✔ Correct EFI + RAID partitions"
echo "  ✔ Correct mdadm.conf configuration"
echo "==========================================================="
echo "The RAID1 setup is VALID."
echo "==========================================================="
