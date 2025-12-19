# Prepare Game Disk

## 0. Variables
```bash
export GAME_DISK="/dev/vdb"
export MOUNT_POINT="/mnt/games"
```

## 1. Make the mount point directory
```bash
sudo mkdir -p "${MOUNT_POINT}"
```

## 2.  Format disk ONLY if no filesystem exists
```bash
if ! sudo blkid "${GAME_DISK}" >/dev/null 2>&1; then
    echo "  - No filesystem found on ${GAME_DISK}"
    echo "  - Formatting ${GAME_DISK} as ext4 (one-time operation)"
    sudo mkfs.ext4 -F "${GAME_DISK}"
else
    echo "  - Filesystem already present on ${GAME_DISK}, skipping format"
fi
```

## 3. Add persistent mount entry if missing
```bash
if ! grep -qs "^${GAME_DISK} ${MOUNT_POINT} " /etc/fstab; then
    echo "  - Adding persistent mount to /etc/fstab"
    echo "${GAME_DISK} ${MOUNT_POINT} ext4 defaults 0 2" | sudo tee -a /etc/fstab >/dev/null
else
    echo "  - /etc/fstab entry already exists"
fi
```

## 4. Mount the filesystem
```bash
sudo mount -a

if mountpoint -q "${MOUNT_POINT}"; then
    echo "  - ${MOUNT_POINT} mounted successfully"
else
    echo "ERROR: Failed to mount ${MOUNT_POINT}"
    exit 1
fi
```

## 5. Fix ownership and permissions
```bash
VM_USER="$(logname 2>/dev/null || echo "${SUDO_USER:-$USER}")"

sudo chown -R "${VM_USER}:${VM_USER}" "${MOUNT_POINT}"
sudo chmod -R 755 "${MOUNT_POINT}"
```

# 6. Create standard game directories
```bash
mkdir -p "${HOME}/Games"
mkdir -p "${MOUNT_POINT}/SteamLibrary"
mkdir -p "${MOUNT_POINT}/BattleNet"
mkdir -p "${MOUNT_POINT}/SC2"
```

## Final: Restart VM
