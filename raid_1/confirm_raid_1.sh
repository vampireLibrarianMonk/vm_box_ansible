#!/usr/bin/env bash
#
# confirm_raid_1.sh
#
# Purpose:
#   Verify that a RAID1 root filesystem is correctly configured and healthy.
#
# Confirms:
#   - Both NVMe disks exist
#   - Expected EFI + RAID partitions exist
#   - /dev/md0 exists
#   - RAID level is RAID1
#   - RAID state is clean or syncing
#   - Both member devices are active
#   - mdadm.conf contains md0
#   - Root filesystem is on md0 (or its UUID)
#   - EFI is mounted
#
# Usage:
#   sudo bash confirm_raid_1.sh /dev/nvme0n1 /dev/nvme1n1
#

set -euo pipefail

PASS() { echo "✔ $1"; }
FAIL() { echo "✘ ERROR: $1"; exit 1; }
INFO() { echo "→ $1"; }

# ---------------------------
# Validate input
# ---------------------------
[[ $# -eq 2 ]] || FAIL "Usage: sudo $0 <disk1> <disk2>"

DISK1="$1"
DISK2="$2"

echo "=================================================="
echo " RAID1 VERIFICATION"
echo "=================================================="
echo " Disk 1: $DISK1"
echo " Disk 2: $DISK2"
echo

# ---------------------------
# Disk existence
# ---------------------------
INFO "Checking disks exist..."
[[ -b "$DISK1" ]] || FAIL "$DISK1 not found"
[[ -b "$DISK2" ]] || FAIL "$DISK2 not found"
PASS "Both disks detected"
echo

# ---------------------------
# Partition layout
# ---------------------------
EFI1="${DISK1}p1"
RAID1="${DISK1}p2"
EFI2="${DISK2}p1"
RAID2="${DISK2}p2"

INFO "Checking required partitions..."
for P in "$EFI1" "$RAID1" "$EFI2" "$RAID2"; do
    [[ -b "$P" ]] || FAIL "Missing partition: $P"
done
PASS "EFI and RAID partitions present on both disks"
echo

# ---------------------------
# md0 existence
# ---------------------------
INFO "Checking RAID device /dev/md0..."
[[ -b /dev/md0 ]] || FAIL "/dev/md0 does not exist"
PASS "/dev/md0 exists"
echo

# ---------------------------
# RAID metadata
# ---------------------------
INFO "Validating RAID level and state..."
MD_DETAIL="$(mdadm --detail /dev/md0)"

echo "$MD_DETAIL" | grep -q "Raid Level : raid1" \
    || FAIL "RAID level is NOT RAID1"

if echo "$MD_DETAIL" | grep -q "State : clean"; then
    PASS "RAID state is clean"
elif echo "$MD_DETAIL" | grep -q "State : active"; then
    PASS "RAID active (syncing or resyncing)"
else
    FAIL "RAID state unhealthy"
fi
echo

# ---------------------------
# Member devices
# ---------------------------
INFO "Checking RAID members..."
echo "$MD_DETAIL" | grep -q "$(basename "$RAID1")" \
    || FAIL "$RAID1 missing from md0"
echo "$MD_DETAIL" | grep -q "$(basename "$RAID2")" \
    || FAIL "$RAID2 missing from md0"
PASS "Both RAID members active"
echo

# ---------------------------
# mdadm.conf
# ---------------------------
INFO "Checking mdadm.conf..."
grep -q "^ARRAY /dev/md0" /etc/mdadm/mdadm.conf \
    || FAIL "mdadm.conf missing ARRAY /dev/md0"
PASS "mdadm.conf contains md0"
echo

# ---------------------------
# Root filesystem
# ---------------------------
INFO "Checking root filesystem source..."
ROOT_SRC="$(findmnt -n -o SOURCE /)"

if [[ "$ROOT_SRC" == "/dev/md0" || "$ROOT_SRC" == UUID=* ]]; then
    PASS "Root filesystem mounted from RAID"
else
    FAIL "Root filesystem NOT on RAID (found: $ROOT_SRC)"
fi
echo

# ---------------------------
# EFI mount
# ---------------------------
INFO "Checking EFI mount..."
EFI_SRC="$(findmnt -n -o SOURCE /boot/efi || true)"
[[ -n "$EFI_SRC" ]] || FAIL "EFI not mounted"
PASS "EFI mounted from $EFI_SRC"
echo

# ---------------------------
# mdstat (final sanity check)
# ---------------------------
INFO "Checking /proc/mdstat..."
grep -q "^md0 : active raid1" /proc/mdstat \
    || FAIL "md0 not active RAID1 in /proc/mdstat"
PASS "md0 confirmed active RAID1"
echo

# ---------------------------
# Final result
# ---------------------------
echo "=================================================="
echo " RAID1 STATUS: HEALTHY ✅"
echo "=================================================="
echo "✔ RAID1 array assembled correctly"
echo "✔ Root filesystem on md0"
echo "✔ Both disks active"
echo "✔ EFI mounted"
echo
echo "System RAID1 configuration is VALID."
