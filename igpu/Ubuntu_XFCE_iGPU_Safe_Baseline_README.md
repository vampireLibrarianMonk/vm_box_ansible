# Ubuntu 22.04 Fresh Install (XFCE + AMD iGPU‑Safe Baseline)

**Target system**
- CPU: AMD Ryzen 7 5700G (Cezanne iGPU)
- dGPU: NVIDIA RTX 3060 (for passthrough later)
- Motherboard: ASUS TUF GAMING B550M‑PLUS WiFi II
- Storage: RAID‑1 (mdadm, root on md0 via UUID)
- Goal: Stable host using AMD iGPU + lightweight desktop (XFCE)

---

## 0. BIOS SETTINGS (DO THIS FIRST)

Enter BIOS → Advanced Mode (F7)

### Boot
- CSM → **Enabled**
- Secure Boot:
  - OS Type → Other OS
  - Secure Boot Keys → **None installed**
- Fast Boot → Disabled
- Boot Mode → UEFI

### Advanced → NB Configuration
- Primary Video Device → **IGFX Video**
- iGPU Multi‑Monitor → Enabled
- UMA Frame Buffer Size → 512M (or Auto if unavailable)

**Important:** Plug monitor into motherboard HDMI/DP, **NOT** the RTX 3060.

Save & Exit.

---

## 1. INSTALL UBUNTU

Boot Ubuntu installer USB:
- Select **Try / Install Ubuntu**
- Press **F6**
- Choose **Safe graphics** (installer only)

Install Ubuntu normally (configure RAID‑1 as required).

---

## 2. FIRST BOOT — INSTALL A MODERN KERNEL (REQUIRED)

Ubuntu 22.04 ships with kernel **5.15**, which contains a known
VGACON ↔ amdgpu race condition that causes black screens on AMD APUs,
especially on RAID systems.

### Install HWE Kernel (6.5+)

```bash
sudo apt update
sudo apt install --install-recommends linux-generic-hwe-22.04
sudo reboot
```

### Confirm Kernel Version

```bash
uname -r
```

Expected:
```
6.5.x-generic  (or newer)
```

---

## 3. GRUB CONFIGURATION (FINAL, CLEAN)

Verify GRUB settings:

```bash
cat /etc/default/grub
```

Ensure **NO graphics‑killing parameters** are present.

### Correct configuration:

```bash
GRUB_CMDLINE_LINUX_DEFAULT="quiet root=UUID=<RAID-UUID> rootdelay=10 rd.auto"
```

> ❌ Do NOT use: `nomodeset`, `video=efifb:off`, `vesafb:off`

Apply changes:

```bash
sudo update-grub
sudo update-initramfs -u
sudo reboot
```

---

## 4. INSTALL LIGHTWEIGHT DESKTOP (XFCE)

From TTY or SSH:

```bash
sudo apt update
sudo apt install -y xfce4 xfce4-goodies
startxfce4
```

Do **NOT** install:
- gdm3
- sddm
- NVIDIA drivers

---

## 5. VERIFY AMD iGPU IS ACTIVE

### Kernel + Driver Check

```bash
uname -r
lsmod | grep amdgpu
```

Expected:
- amdgpu module loaded

### PCI Driver Binding

```bash
lspci -nnk | grep -A3 VGA
```

Expected:
- AMD Cezanne
- `Kernel driver in use: amdgpu`

### DRM Devices

```bash
ls /sys/class/drm/
```

Expected:
- cardX entries
- renderD128

### Kernel Log Confirmation

```bash
dmesg | grep -i amdgpu | tail -20
```

Expected:
- `[drm] Initialized amdgpu`
- `fb0: amdgpudrmfb frame buffer device`

---

## 6. SAFE OPERATING RULES

- Keep monitor connected to motherboard output
- Do NOT install NVIDIA drivers on host
- Do NOT re‑enable Secure Boot
- Do NOT add `nomodeset`
- Use XFCE without a display manager

---

## 7. READY FOR GPU PASSTHROUGH

System is now stable and graphics‑safe.

You may now:
- Enable IOMMU
- Bind RTX 3060 to `vfio-pci`
- Create libvirt / KVM VMs
- Automate passthrough with Ansible

---

## SUCCESS CHECK

```bash
lspci | grep -Ei "vga|display"
```

Expected:
- AMD iGPU only

---

## FINAL NOTE

This configuration permanently resolves black‑screen boot failures on
Ubuntu 22.04 systems using:
- AMD Ryzen APUs
- UEFI
- mdadm RAID
- Headless‑lean or lightweight desktop setups

Kernel 6.5+ eliminates the amdgpu VGACON race entirely.

