#!/usr/bin/env bash
set -Eeuo pipefail

###############################################################################
# In-Guest Gaming VM Setup (Idempotent)
#
# - Safely formats and mounts /dev/vdb to /mnt/games (one-time)
# - Persists mount via /etc/fstab (no duplicates)
# - Installs NVIDIA drivers automatically (if not already installed)
# - Applies permanent NVIDIA passthrough primary display fixes (Xorg + GDM)
# - Installs Steam, Flatpak Lutris, Wine, Vulkan (32-bit + 64-bit)
# - Creates standard game directories
#
# Safe to re-run. No destructive actions after first run.
###############################################################################

GAME_DISK="/dev/vdb"
MOUNT_POINT="/mnt/games"
REBOOT_REQUIRED=0

echo "============================================================"
echo " In-Guest Gaming VM Setup"
echo "============================================================"
echo ""

###############################################################################
# 0. OpenSSH Server Setup
###############################################################################

echo "[0/5] Setting up OpenSSH Server..."

# Install OpenSSH server
sudo apt-get update
sudo apt-get install -y openssh-server

# Enable and start SSH service
sudo systemctl enable --now ssh

# Diagnostic: confirm SSH is listening on port 22
echo "  - Verifying SSH is listening on port 22:"
ss -tlnp | grep ':22' || echo "WARNING: SSH is not listening on port 22"

###############################################################################
# 1. Prepare and mount game disk
###############################################################################

echo "[1/5] Preparing game disk..."

sudo mkdir -p "${MOUNT_POINT}"

# Format disk ONLY if no filesystem exists
if ! sudo blkid "${GAME_DISK}" >/dev/null 2>&1; then
    echo "  - No filesystem found on ${GAME_DISK}"
    echo "  - Formatting ${GAME_DISK} as ext4 (one-time operation)"
    sudo mkfs.ext4 -F "${GAME_DISK}"
else
    echo "  - Filesystem already present on ${GAME_DISK}, skipping format"
fi

# Add persistent mount entry if missing
if ! grep -qs "^${GAME_DISK} ${MOUNT_POINT} " /etc/fstab; then
    echo "  - Adding persistent mount to /etc/fstab"
    echo "${GAME_DISK} ${MOUNT_POINT} ext4 defaults 0 2" | sudo tee -a /etc/fstab >/dev/null
else
    echo "  - /etc/fstab entry already exists"
fi

echo "  - Mounting filesystems"
sudo mount -a

if mountpoint -q "${MOUNT_POINT}"; then
    echo "  - ${MOUNT_POINT} mounted successfully"
else
    echo "ERROR: Failed to mount ${MOUNT_POINT}"
    exit 1
fi

# Fix ownership and permissions
VM_USER="$(logname 2>/dev/null || echo "${SUDO_USER:-$USER}")"

sudo chown -R "${VM_USER}:${VM_USER}" "${MOUNT_POINT}"
sudo chmod -R 755 "${MOUNT_POINT}"

echo ""

###############################################################################
# 2. Install NVIDIA drivers (idempotent)
###############################################################################

echo "[2/5] Ensuring NVIDIA drivers are installed..."

if ! command -v nvidia-smi >/dev/null 2>&1; then
    echo "  - NVIDIA drivers not detected"
    echo "  - Installing recommended NVIDIA drivers"
    sudo apt update
    sudo ubuntu-drivers autoinstall
    REBOOT_REQUIRED=1
else
    echo "  - NVIDIA drivers already installed"
fi

echo ""

###############################################################################
# 3. NVIDIA Passthrough Primary Display Fix (Ubuntu 22.04)
###############################################################################

echo "[3/5] Applying NVIDIA passthrough display fixes..."

# 1️⃣ Force Xorg to bind NVIDIA as primary GPU
sudo mkdir -p /etc/X11/xorg.conf.d

sudo tee /etc/X11/xorg.conf.d/10-nvidia.conf >/dev/null <<'EOF'
Section "Device"
    Identifier     "NvidiaGPU"
    Driver         "nvidia"
    VendorName     "NVIDIA Corporation"
    Option         "PrimaryGPU" "yes"
    Option         "AllowEmptyInitialConfiguration"
EndSection
EOF

# 2️⃣ Permanently disable Wayland (required for NVIDIA passthrough)
#     (GDM reads this file; keep it minimal and exact)
sudo tee /etc/gdm3/custom.conf >/dev/null <<'EOF'
[daemon]
WaylandEnable=false
EOF

# 3️⃣ Ensure NVIDIA DRM modeset is enabled + modules load early (boot-time requirement)
echo "options nvidia-drm modeset=1" | sudo tee /etc/modprobe.d/nvidia-drm.conf >/dev/null

# Load NVIDIA modules early on boot (prevents “works once / black screen” races)
sudo tee /etc/modules-load.d/nvidia.conf >/dev/null <<'EOF'
nvidia
nvidia_modeset
nvidia_uvm
nvidia_drm
EOF

# Force kernel param too (most reliable across driver versions)
if ! grep -q 'nvidia-drm.modeset=1' /etc/default/grub; then
  sudo sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="nvidia-drm.modeset=1 /' /etc/default/grub
fi

# Rebuild initramfs + update grub so changes persist across reboot
sudo update-initramfs -u
sudo update-grub
REBOOT_REQUIRED=1

echo "  - NVIDIA display configuration applied (Xorg forced, DRM modeset forced)"
echo ""


###############################################################################
# 4. Install gaming packages (UPDATED LUTRIS SETUP)
###############################################################################

echo "[4/5] Installing gaming packages..."

echo "  - Enabling 32-bit architecture"
sudo dpkg --add-architecture i386 || true

sudo apt update

echo "  - Installing Steam, Wine, Vulkan (APT)"
sudo apt install -y \
    steam \
    wine64 \
    wine32 \
    winetricks \
    libvulkan1 \
    libvulkan1:i386 \
    flatpak

echo "  - Removing broken APT Lutris (if present)"
sudo apt remove -y lutris || true

echo "  - Ensuring Flathub is configured"
sudo flatpak remote-add --if-not-exists \
    flathub https://flathub.org/repo/flathub.flatpakrepo

echo "  - Granting Lutris Flatpak access to /mnt"
flatpak override --user --filesystem=/mnt net.lutris.Lutris

echo "  - Installing Lutris (Flatpak)"
flatpak install -y flathub net.lutris.Lutris

echo "  - Installing ProtonPlus (Flatpak)"
flatpak install -y flathub com.vysp3r.ProtonPlus

echo ""

###############################################################################
# 5. Create standard game directories
###############################################################################

echo "[5/5] Creating game directories..."

mkdir -p "${HOME}/Games"
mkdir -p "${MOUNT_POINT}/SteamLibrary"
mkdir -p "${MOUNT_POINT}/BattleNet"
mkdir -p "${MOUNT_POINT}/SC2"

echo ""

###############################################################################
# Final summary
###############################################################################

echo "============================================================"
echo " Setup Complete"
echo "============================================================"
echo ""
echo "Game disk mount point:       ${MOUNT_POINT}"
echo "Steam library path:          ${MOUNT_POINT}/SteamLibrary"
echo "Battle.net install path:     ${MOUNT_POINT}/BattleNet"
echo "StarCraft II install path:   ${MOUNT_POINT}/SC2"
echo ""

if [[ "${REBOOT_REQUIRED}" -eq 1 ]]; then
    echo "IMPORTANT:"
    echo "  System changes require a reboot."
    echo ""
    echo "      sudo reboot"
else
    echo "No reboot required."
fi

cat <<'EOF'

## Next Steps (Post-Setup — Required)

⚠️  Do not skip these steps. The default Lutris runner will cause Battle.net issues.

### 1. Reboot (if prompted)

    sudo reboot

### 2. Launch Lutris (Flatpak)

    flatpak run net.lutris.Lutris

### 3. Configure the correct Wine runner BEFORE installing Battle.net

1. In Lutris, click:
       ☰ → Preferences → Runners
2. Scroll to:
       Wine
3. Click the gear icon
4. Set Wine version to ONE of the following:
       - Proton-GE (latest)
         OR
       - Highest available Wine 10.x / GE runner
5. Ensure:
       DXVK is enabled
6. Click:
       Save

❗ Using the default Lutris Wine runner WILL break Battle.net updates and UI.

### 4. Install Battle.net

1. Open a browser and go to:
       https://lutris.net/games/battlenet/
2. Click:
       Install
   (This will open Lutris)
3. When prompted for install location, select:
       /mnt/games/BattleNet

### 5. Verify Battle.net runner configuration

1. Right-click:
       Battle.net → Configure
2. Open:
       Runner options
3. Confirm Wine version matches:
       Proton-GE / Wine 10.x
4. Click:
       Save

### 6. Launch Battle.net and allow it to update

- Log in to your Blizzard account
- Allow the client to fully update (1–2 minutes)

### 7. Install StarCraft (base game)

1. In Battle.net, select:
       StarCraft
2. Click:
       Install
3. Set the install path to:
       /mnt/games/SC2

### 8. First launch verification

- Launch StarCraft once from Battle.net
- Confirm the game reaches the main menu

EOF
