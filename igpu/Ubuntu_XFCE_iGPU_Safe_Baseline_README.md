# Ubuntu 22.04 Fresh Install (XFCE + iGPU-Safe Baseline)

**Target system**
- CPU: AMD Ryzen 7 5700G (Cezanne iGPU)
- dGPU: NVIDIA RTX 3060 (for passthrough later)
- Motherboard: ASUS TUF GAMING B550M-PLUS WiFi II
- Storage: RAID-1 (/dev/md0)
- Goal: Stable host using iGPU + lightweight desktop (XFCE)

---

## 0. BIOS SETTINGS (DO THIS FIRST)

Enter BIOS → Advanced Mode (F7)

### Boot
- CSM → Enabled
- Secure Boot:
  - OS Type → Other OS
  - Secure Boot Keys → **None installed**
- Fast Boot → Disabled
- Boot Mode → UEFI

### Advanced → NB Configuration
- Primary Video Device → IGFX Video
- iGPU Multi-Monitor → Enabled
- UMA Frame Buffer Size → 512M

**Important:** Plug monitor into motherboard HDMI/DP, NOT the RTX 3060.

Save & Exit.

---

## 1. INSTALL UBUNTU

Boot Ubuntu installer USB:
- Select Try / Install Ubuntu
- Press F6
- Choose Safe graphics

Install Ubuntu normally (RAID setup as required).

---

## 2. FIRST BOOT — VERIFY GRUB

Check GRUB configuration:

```bash
cat /etc/default/grub
```

It must contain:

```bash
GRUB_CMDLINE_LINUX_DEFAULT="quiet root=/dev/md0 rootdelay=10 rd.auto video=efifb:off"
```

Apply changes:

```bash
sudo update-grub
sudo update-initramfs -u -k all
```

Reboot once.

---

## 3. INSTALL LIGHTWEIGHT DESKTOP (XFCE)

From a TTY login:

```bash
sudo apt update
sudo apt install -y xfce4 xfce4-goodies
startxfce4
```

Do NOT install:
- gdm3
- sddm
- NVIDIA drivers

---

## 4. VERIFY iGPU IS IN USE

Run:

```bash
lspci -nnk | grep -A4 -Ei "vga|display"
```

Expected:
- AMD Cezanne
- Kernel modules: amdgpu

```bash
lsmod | grep -E "nvidia|nouveau|simple"
```

Expected: **no output**

```bash
loginctl show-session $(loginctl | awk '/tty/{print $1}') -p Type
```

Expected:
```text
Type=tty
```

---

## 5. SAFE OPERATING RULES

- Use startxfce4 (no display manager)
- Do NOT install NVIDIA drivers on host
- Do NOT re-enable Secure Boot
- Do NOT add nomodeset to GRUB
- Keep monitor on motherboard output

---

## 6. READY FOR GPU PASSTHROUGH

You may now safely:
- Enable IOMMU
- Bind RTX 3060 to vfio-pci
- Develop Ansible GPU passthrough roles
- Create libvirt VMs

---

## SUCCESS CHECK

```bash
lspci | grep -Ei "vga|display"
```

Should list AMD only.

---

## FINAL NOTE

Following this guide prevents black screens and firmware conflicts on
Ryzen APU + NVIDIA passthrough systems.
