# NVIDIA drivers

## 1. Installing Vulkan/OpenGL diagnostic tools
```bash
sudo apt update
sudo apt install -y mesa-utils vulkan-tools
```

## 2. NVIDIA + Vulkan sanity checks..."
```bash
nvidia-smi || echo "WARNING: nvidia-smi failed"

glxinfo | grep "OpenGL renderer" || echo "WARNING: OpenGL renderer not detected"

vulkaninfo | head -n 5 || echo "WARNING: Vulkan info failed"
```

## 3. Install NVIDIA 580 driver stack
```bash
sudo apt install -y \
  nvidia-driver-580 \
  libnvidia-gl-580 \
  libnvidia-gl-580:i386 \
  nvidia-utils-580
```

## 4. Display Manager hardening (REQUIRED for GPU passthrough)

### Disabling Wayland (required for NVIDIA passthrough)..."
```bash
if [ -f /etc/gdm3/custom.conf ]; then
  sudo sed -i 's/^#WaylandEnable=false/WaylandEnable=false/' /etc/gdm3/custom.conf
  sudo sed -i 's/^WaylandEnable=true/WaylandEnable=false/' /etc/gdm3/custom.conf
else
  echo "WARNING: /etc/gdm3/custom.conf not found"
fi
```

### Forcing NVIDIA as primary GPU (Xorg)
```bash
sudo mkdir -p /etc/X11/xorg.conf.d

sudo tee /etc/X11/xorg.conf.d/10-nvidia-primary.conf >/dev/null <<'EOF'
Section "Device"
    Identifier  "NVIDIA GPU"
    Driver      "nvidia"
    Option      "PrimaryGPU" "true"
EndSection
EOF
```

## 5. Update initramfs to ensure NVIDIA loads early
```bash
sudo update-initramfs -u
```

## Final: Restart VM