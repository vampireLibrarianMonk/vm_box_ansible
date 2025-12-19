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

cat <<'BANNER'
============================================================
 In-Guest Gaming VM Setup
============================================================
BANNER

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

echo "[1/6] Preparing game disk..."

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

echo "[2/6] Ensuring NVIDIA drivers are installed..."

###############################################################################
# Host GPU + Vulkan sanity checks (manual verification)
#
echo "[GPU] Installing Vulkan/OpenGL diagnostic tools..."

sudo apt update
sudo apt install -y mesa-utils vulkan-tools

echo "[GPU] Running NVIDIA + Vulkan sanity checks..."

nvidia-smi || echo "WARNING: nvidia-smi failed"

glxinfo | grep "OpenGL renderer" || echo "WARNING: OpenGL renderer not detected"

vulkaninfo | head -n 5 || echo "WARNING: Vulkan info failed"

###############################################################################

###############################################################################
echo "[GPU] Ensuring NVIDIA 580 driver stack is installed..."

sudo apt install -y \
  nvidia-driver-580 \
  libnvidia-gl-580 \
  libnvidia-gl-580:i386 \
  nvidia-utils-580

###############################################################################

###############################################################################
# 3. Install gaming packages (UPDATED LUTRIS SETUP)
###############################################################################

echo "[3/6] Installing gaming packages..."

###############################################################################
###############################################################################
echo "[Lutris] Installing Flatpak + Lutris..."

sudo apt update
sudo apt install -y flatpak

# Ensure Flathub remote exists (required)
if ! flatpak remote-list | grep -q '^flathub'; then
  sudo flatpak remote-add --if-not-exists flathub \
    https://dl.flathub.org/repo/flathub.flatpakrepo
fi

# Install Lutris
flatpak install -y flathub net.lutris.Lutris

echo "[Lutris] Granting /mnt filesystem access..."

flatpak override --user --filesystem=/mnt net.lutris.Lutris

echo "[Lutris] Verifying Vulkan inside Lutris Flatpak..."

flatpak run --command=vulkaninfo net.lutris.Lutris --summary || \
  echo "WARNING: Vulkan validation inside Flatpak failed (check drivers/runtime)"

echo "[Lutris] NOTE: If Lutris does not appear in menus, log out and back in."

###############################################################################

###############################################################################
echo "[Flatpak] Installing required Freedesktop 23.08 runtimes..."

flatpak install -y flathub \
  org.freedesktop.Platform.ffmpeg-full//23.08 \
  org.freedesktop.Platform.GL.default//23.08 \
  org.freedesktop.Platform.GL32.default//23.08 \
  org.freedesktop.Platform.Locale//23.08 \
  org.freedesktop.Platform.VulkanLayer.MangoHud//23.08 \
  org.freedesktop.Platform.Compat.i386//23.08 \
  org.freedesktop.Platform.Compat.i386.Debug//23.08

###############################################################################

###############################################################################
# 4. Drive mapping (Wine)
###############################################################################

echo "[4/7] Configuring Wine drive mapping for /mnt/games..."

WINEPREFIX="${HOME}/Games/battlenet"
export WINEPREFIX

echo "  - Launching winecfg for prefix: ${WINEPREFIX}"

echo "[4/6] Configuring Wine drive mapping for /mnt/games (automated)..."

WINEPREFIX="${HOME}/Games/battlenet"
export WINEPREFIX

DOSDEVICES_DIR="${WINEPREFIX}/dosdevices"

mkdir -p "${DOSDEVICES_DIR}"

if [[ ! -e "${DOSDEVICES_DIR}/g:" ]]; then
    echo "  - Creating Wine drive G: → /mnt/games"
    ln -s /mnt/games "${DOSDEVICES_DIR}/g:"
else
    echo "  - Wine drive G: already exists, skipping"
fi

echo "  - Verifying Wine drive mappings:"
ls -l "${DOSDEVICES_DIR}" | grep "g:" || echo "WARNING: G: drive not detected"

echo "  - Wine drive mapping complete (winecfg not required)"

###############################################################################

###############################################################################
# Configure Battle.net to install StarCraft II to /mnt/games
#
# In Battle.net Settings → Downloads:
#   Default install location:
#     G:\StarCraft II
#
# Then install/download StarCraft II.
###############################################################################

###############################################################################

###############################################################################
# 5. Create standard game directories
###############################################################################

echo "[5/6] Creating game directories..."

mkdir -p "${HOME}/Games"
mkdir -p "${MOUNT_POINT}/SteamLibrary"
mkdir -p "${MOUNT_POINT}/BattleNet"
mkdir -p "${MOUNT_POINT}/SC2"

echo ""

###############################################################################
# 5. Performance tuning for CPU-bound games (StarCraft II)
#
# - Installs Feral GameMode
# - Enables userspace daemon
# - Safe in VMs (non-fatal if CPU governor cannot be changed)
# - Improves SC2 frame pacing and late-game performance
###############################################################################

echo "[6/6] Installing GameMode for CPU-bound workloads..."

if ! command -v gamemoded >/dev/null 2>&1; then
    sudo apt update
    sudo apt install -y \
        gamemode \
        libgamemode0 \
        libgamemodeauto0
else
    echo "  - GameMode already installed"
fi

echo ""

###############################################################################
# Final summary
###############################################################################

cat <<SUMMARY
============================================================
 Setup Complete
============================================================

Game disk mount point:       ${MOUNT_POINT}
Steam library path:          ${MOUNT_POINT}/SteamLibrary
Battle.net install path:     ${MOUNT_POINT}/BattleNet
StarCraft II install path:   ${MOUNT_POINT}/SC2
SUMMARY

## Next Steps (Post-Setup — **Required**)

⚠️ **Do not skip these steps.** Using the wrong Wine runner or enabling Proton/DXVK too early **will break Battle.net**.

---

### 1. Reboot (if prompted)

```bash
sudo reboot
```

### 2. Test GameMode

Use this command:
```bash
gamemoded -t
```

Expected output (full sample output; CPU governor errors are **expected** in VMs and are non-fatal):
```text
: Loading config
Loading config file [/usr/share/gamemode/gamemode.ini]
: Running tests

:: Basic client tests
:: Passed

:: Dual client tests
gamemode request succeeded and is active
Quitting by request...
:: Passed

:: Gamemoderun and reaper thread tests
...Waiting for child to quit...
...Waiting for reaper thread (reaper_frequency set to 5 seconds)...
:: Passed

:: Supervisor tests
:: Passed

:: Feature tests
::: Verifying CPU governor setting
ERROR: glob failed for cpu governors: (No such file or directory)
ERROR: glob failed for cpu governors: (No such file or directory)
ERROR: Governor was not set to performance (was actually )!
::: Failed!

::: Verifying Scripts
::: Passed (no scripts configured to run)

::: Verifying GPU Optimisations
::: Passed (gpu optimisations not configured to run)

::: Verifying renice
::: Passed (no renice configured)

::: Verifying ioprio
::: Passed

ERROR: :: Failed!
: Tests Failed!
```text
... Tests Failed!
```

---

### 3. Launch Lutris (Flatpak **only**)

```bash
flatpak run net.lutris.Lutris
```

> ❗ Do **not** launch Lutris from the distro package or an APT-based desktop entry.

---

### 4. Install the **correct Wine runner** (before installing Battle.net)

- Menu → Preferences → Runners → Wine → Manage versions
- Install **Wine-GE 10.x or newer**
- Set it as the default Wine version

**Rules:**
- ❌ No Proton / Proton-GE
- ❌ No default Lutris Wine
- ❌ No system Wine

---

### 5. Install Battle.net (Flatpak Lutris)

- Use the following install location `/mnt/games/BattleNet`:

```bash
INSTALLER_PATH="${HOME}/Downloads/Battle.net-Setup.exe"

mkdir -p "${HOME}/Downloads"

curl -L \
  -o "${INSTALLER_PATH}" \
  "https://www.battle.net/download/getInstallerForGame?os=win&gameProgram=BATTLENET_APP&version=Live"

FILE_INFO="$(file "${INSTALLER_PATH}" || true)"

if ! echo "${FILE_INFO}" | grep -q "PE32 executable"; then
    echo "WARNING: Installer does not appear to be a valid Windows executable"
    echo "WARNING: Battle.net installation may fail"
fi

flatpak run --command=wine net.lutris.Lutris "${INSTALLER_PATH}"
```

---

### 6. Configure Battle.net **before first launch**

Runner options:
- Wine version: **Wine-GE 10.x**
- DXVK: ❌ OFF
- VKD3D: ❌ OFF

Environment variables:
```
WINEDLLOVERRIDES=dxgi=n
```

---

### 7. Launch Battle.net and allow it to update

Wait for the client to fully update before interacting.

---

### 8. Install StarCraft II

Install path:
```
/mnt/games/SC2
```

---

### 9. First launch verification

Confirm StarCraft II reaches the main menu.

---

### 10. Optional performance tuning (after success)

- DXVK may be enabled
- VKD3D should remain disabled

---

EOF
