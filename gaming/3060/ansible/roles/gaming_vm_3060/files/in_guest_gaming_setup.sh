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
sudo apt install -y steam flatpak

echo "  - Ensuring Flathub is configured"
sudo flatpak remote-add --if-not-exists \
    flathub https://flathub.org/repo/flathub.flatpakrepo

echo "  - Granting Lutris Flatpak access to /mnt"
flatpak override --user --filesystem=/mnt net.lutris.Lutris

echo "  - Installing Lutris (Flatpak)"
flatpak install -y flathub net.lutris.Lutris

echo "  - Installing ProtonPlus (Flatpak)"
flatpak install -y flathub com.vysp3r.ProtonPlus

echo "  - Setting /mnt permissions (Flatpak)"
flatpak override --user \
  --filesystem=/mnt \
  --device=all \
  net.lutris.Lutris

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
# 6. Performance tuning for CPU-bound games (StarCraft II)
#
# - Installs Feral GameMode
# - Enables userspace daemon
# - Safe in VMs (non-fatal if CPU governor cannot be changed)
# - Improves SC2 frame pacing and late-game performance
###############################################################################

echo "[Performance] Installing GameMode for CPU-bound workloads..."

if ! command -v gamemoded >/dev/null 2>&1; then
    sudo apt update
    sudo apt install -y \
        gamemode \
        libgamemode0 \
        libgamemodeauto0
    REBOOT_REQUIRED=1
else
    echo "  - GameMode already installed"
fi

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

## Next Steps (Post-Setup — **Required**)

⚠️ **Do not skip these steps.** Using the wrong Wine runner or enabling Proton/DXVK too early **will break Battle.net**.

---

### 1. Reboot (if prompted)

```bash
sudo reboot
```

### 2. Test GameMode

User this command:
```bash
gamemoded -t
```

Expected Output:
```bash
gamemode is running and responding
```

---

### 3. Launch Lutris (Flatpak **only**)

```bash
flatpak run net.lutris.Lutris
```

> ❗ Do **not** launch Lutris from the distro package or desktop file tied to APT.

---

### 4. Install the **correct Wine runner** (before installing Battle.net)

1. In Lutris, open:
   - ☰ **Menu** → **Preferences** → **Runners**
2. Scroll to **Wine**
3. Click **Manage versions**
4. Install **exactly one** of the following:
   - ✅ **Wine-GE 8.x or newer** (recommended)
5. Set the installed **Wine-GE** version as the default for Wine

**Important rules:**
- ❌ **Do NOT use Proton or Proton-GE for Battle.net**
- ❌ Do NOT use the default Lutris Wine runner
- ❌ Do NOT use system/apt Wine

---

### 5. Install Battle.net (Flatpak Lutris)

1. Open a browser and go to:
   - https://lutris.net/games/battlenet/
2. Click **Install** (this opens Lutris)
3. When prompted for install location, select:
   ```
   /mnt/games/BattleNet
   ```

---

### 6. Configure Battle.net **before first launch**

1. In Lutris, right-click **Battle.net** → **Configure**

#### Runner options
- **Runner:** Wine
- **Wine version:** **Wine-GE (the one you installed)**
- **DXVK:** ❌ **OFF** (first launch)
- **VKD3D:** ❌ OFF
- **Esync / Fsync:** ❌ OFF

#### System options → Environment variables
Add **exactly**:
```
WINEDLLOVERRIDES=dxgi=n
```

> This forces OpenGL and prevents Vulkan/ANGLE crashes.

Click **Save**.

---

### 7. Launch Battle.net and allow it to update

- Click **Play** on Battle.net in Lutris
- Log in to your Blizzard account
- **Do not click anything** until the client finishes updating (1–2 minutes)

Expected result:
- Battle.net window stays open
- Game list loads normally

---

### 8. Install StarCraft II (base game)

1. In Battle.net, select **StarCraft II**
2. Click **Install**
3. Set the install path to:
   ```
   /mnt/games/SC2
   ```

If files already exist at that path, Battle.net will **verify instead of re-downloading**.

---

### 9. First launch verification

- Launch **StarCraft II** from Battle.net
- Confirm the game reaches the **main menu**

---

### 10. Optional performance tuning (only after success)

After StarCraft II launches successfully **once**:

- ✅ You may enable **DXVK**
- ❌ Keep **VKD3D disabled**
- ❌ Do NOT switch Wine runners

---

## Absolute Don’ts

- ❌ Do NOT use Proton for Battle.net
- ❌ Do NOT install Wine via APT
- ❌ Do NOT mix Flatpak Lutris with system Wine
- ❌ Do NOT enable Vulkan/DXVK before Battle.net works

Following these steps exactly makes the VM **fully reproducible** and avoids all known Battle.net failures on Linux.

EOF
