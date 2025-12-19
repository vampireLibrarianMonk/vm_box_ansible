# Gaming Packages (Lutris)

## 1. Update and install flatpak
```bash
sudo apt update
sudo apt install -y flatpak
```

## 2. Ensure Flathub remote exists (required)
```bash
if ! flatpak remote-list | grep -q '^flathub'; then
  sudo flatpak remote-add --if-not-exists flathub \
    https://dl.flathub.org/repo/flathub.flatpakrepo
fi
```

## 3. Install Lutris
```bash
flatpak install -y flathub net.lutris.Lutris
```

## 4. Granting /mnt filesystem access
```bash
flatpak override --user --filesystem=/mnt net.lutris.Lutris
```

## 5. Verify Vulkan inside Lutris Flatpak
```bash
flatpak run --command=vulkaninfo net.lutris.Lutris --summary || \
  echo "WARNING: Vulkan validation inside Flatpak failed (check drivers/runtime)"
```

## NOTE: If Lutris does not appear in menus, log out and back in.

## 6. Installing required Freedesktop 23.08 runtimes
```bash
flatpak install -y flathub \
  org.freedesktop.Platform.ffmpeg-full//23.08 \
  org.freedesktop.Platform.GL.default//23.08 \
  org.freedesktop.Platform.GL32.default//23.08 \
  org.freedesktop.Platform.Locale//23.08 \
  org.freedesktop.Platform.VulkanLayer.MangoHud//23.08 \
  org.freedesktop.Platform.Compat.i386//23.08 \
  org.freedesktop.Platform.Compat.i386.Debug//23.08
```

## Final: Restart VM