# Stage 1 — Game Disk Setup

This step prepares shared storage and defines the gaming VM with attached disks.

## Command

```bash
sudo bash scripts/game_disk_setup.sh DISK_SIZE
```

## Expected Result (using 80G)

```bash
 bash scripts/game_disk_setup.sh 80G
=== Shared Game Data Disk Setup ===
Disk size: 80G
VM storage directory: /home/user/vms
[1] Ensuring VM storage directory exists...
[2] Checking qemu-img availability...
[3] Creating or validating game data disk...
Creating /home/user/vms/game-data.qcow2 (80G, thin provisioned)...
Formatting '/home/user/vms/game-data.qcow2', fmt=qcow2 cluster_size=65536 extended_l2=off compression_type=zlib size=85899345920 lazy_refcounts=off refcount_bits=16
=== Game Data Disk Setup Complete ===
Location: /home/user/vms/game-data.qcow2

Attach this disk to gaming VMs as a second virtio disk (vdb).
Inside the VM, mount to /mnt/games and update fstab accordingly.
```
