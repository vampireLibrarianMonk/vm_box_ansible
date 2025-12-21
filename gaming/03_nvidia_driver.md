# NVIDIA drivers

## 0. Stop & Disable Display Managers (CRITICAL)
**Never install NVIDIA drivers with a running display manager.**

```bash
# Stop display managers (ignore if not installed or not running)
sudo systemctl stop gdm 2>/dev/null || true
sudo systemctl stop sddm 2>/dev/null || true

# Disable GDM to prevent Wayland fallback and auto-respawn
if systemctl list-unit-files | grep -q '^gdm\.service'; then
    echo "  - Disabling GDM..."
    sudo systemctl disable gdm || true
fi
```

## 1. Installing Vulkan/OpenGL diagnostic tools
```bash
sudo apt update
sudo apt install -y mesa-utils vulkan-tools
```

## 2. Install NVIDIA 580 driver stack
```bash
sudo apt install -y \
  nvidia-driver-580 \
  libnvidia-gl-580 \
  libnvidia-gl-580:i386 \
  nvidia-utils-580
```

## REBOOT VM with virtual manager or destroy command

## 3. Blacklist Nouveau (Required)
```bash
sudo tee /etc/modprobe.d/blacklist-nouveau.conf >/dev/null <<'EOF'
blacklist nouveau
options nouveau modeset=0
EOF

sudo update-initramfs -u
```

## 4. Force Early NVIDIA DRM Modesetting
```bash
echo 'options nvidia-drm modeset=1' | sudo tee /etc/modprobe.d/nvidia-drm.conf
```

## 5. Disable Wayland (Hard Requirement)

### GDM (if present)

```bash
sudo sed -i 's/^#WaylandEnable=false/WaylandEnable=false/' /etc/gdm3/custom.conf || true
sudo sed -i 's/^WaylandEnable=true/WaylandEnable=false/' /etc/gdm3/custom.conf || true
```

Verify:

```bash
grep WaylandEnable /etc/gdm3/custom.conf
```

Expected:
```
WaylandEnable=false
```

> If you use **SDDM**, Wayland is completely eliminated.

---

## 6. Force NVIDIA as Primary GPU (Xorg-Pinned)

### Xorg NVIDIA Configuration

```bash
sudo mkdir -p /etc/X11/xorg.conf.d

sudo tee /etc/X11/xorg.conf.d/10-nvidia.conf >/dev/null <<'EOF'
Section "Files"
    ModulePath "/usr/lib/nvidia/xorg"
    ModulePath "/usr/lib/xorg/modules"
EndSection

Section "Device"
    Identifier "NVIDIA GPU"
    Driver "nvidia"
    Option "PrimaryGPU" "true"
    Option "AllowEmptyInitialConfiguration" "true"
EndSection
EOF
```

Verify driver path exists:

```bash
dpkg -L xserver-xorg-video-nvidia-580 | grep nvidia_drv.so
```

Expected:
```
/usr/lib/x86_64-linux-gnu/nvidia/xorg/nvidia_drv.so
```

---

## 7. Install & Enforce SDDM (Safer Than GDM)

```bash
sudo apt-get install -y sddm
sudo systemctl enable sddm
```

### Force SDDM as Default Display Manager (MANDATORY)

```bash
echo /usr/bin/sddm | sudo tee /etc/X11/default-display-manager
```

Verify:

```bash
cat /etc/X11/default-display-manager
```

Expected:
```
/usr/bin/sddm
```

---

## 8. Force SDDM to X11 Only

```bash
sudo mkdir -p /etc/sddm.conf.d

sudo tee /etc/sddm.conf.d/10-x11.conf >/dev/null <<'EOF'
[General]
DisplayServer=x11
EOF
```

---

## 9. Update GRUB for NVIDIA DRM

Edit GRUB:

```bash
sudo nano /etc/default/grub
```

Change:
```
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"
```

To:
```
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash nvidia-drm.modeset=1"
```

Apply:

```bash
sudo update-grub
sudo update-initramfs -u
```

---

## 10. Manual Xorg Validation (Highly Recommended)

```bash
sudo systemctl stop sddm
sudo Xorg :0 -verbose 3
```

- Errors → configuration issue printed explicitly
- Starts and sits there → **SUCCESS** (Ctrl+C to exit)

Restart SDDM:

```bash
sudo systemctl start sddm
```

---

## 11. Reboot

```bash
sudo reboot
```

---

## 12. Post-Boot Verification

### Confirm X11 Session

```bash
loginctl show-session $(loginctl | awk '/tty/{print $1}') -p Type
```

Expected:
```
Type=x11
```

### Confirm NVIDIA Owns Rendering

```bash
glxinfo | grep "OpenGL renderer"
```

Expected:
```
NVIDIA GeForce RTX 3060
```

### Confirm Driver Health

```bash
nvidia-smi || echo "WARNING: nvidia-smi failed"

glxinfo | grep "OpenGL renderer" || echo "WARNING: OpenGL renderer not detected"

vulkaninfo | head -n 5 || echo "WARNING: Vulkan info failed"
```

## Final: Restart VM