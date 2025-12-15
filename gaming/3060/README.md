# RTX 3060 Passthrough Gaming VM — Step-by-Step Guide

This document describes the **exact, validated sequence** to bring up the RTX 3060 passthrough gaming VM.

---

## Stage 1 — RTX 3060 Gaming VM (Definition Only)

This stage defines the gaming VM and attaches disks.  
**No GPU is attached yet.**

### Command
```bash
ansible-playbook gaming/3060/ansible/create_3060_gaming_vm.yml --ask-become-pass
```

### Expected Result
- Gaming VM appears in **virt-manager**
- Shared `game-data.qcow2` disk attached
- In-guest setup script staged and path printed

---

## Stage 2 — GPU Passthrough (Host Action)

Run on the **host**:

```bash
bash scripts/gaming/3060/gpu_passthrough_config.sh
```

### Expected Result
- RTX 3060 GPU and HDMI audio PCI IDs detected
- Clear virt-manager instructions printed

---

## Stage 3 — Attach GPU & Boot VM (Manual, Required)

### 0. Ensure you enable [SVM](setup/README_Enable_AMD-V_ASUS_TUF_B550M.md)

### 1. Open virt-manager
```bash
virt-manager
```

### 2. Modify `gpu-3060-gaming` (VM must be **OFF**)

View the details via open --> view details:

#### Add PCI Devices
- **Add Hardware → PCI Host Device**
  - `01:00.0` → NVIDIA RTX 3060 GPU
  - `01:00.1` → NVIDIA HDMI Audio

#### Remove Virtual Graphics
- Remove **Video Virtio**

More detailed steps [here](gaming/3060/suppliment_video_virtio.md)

#### Display
- Set **Display → None**

#### Firmware (Verify)
- Must be **UEFI (OVMF)**

---

## Stage 4 — Boot Method (IMPORTANT)

- Plug a **monitor directly into the RTX 3060**
- Keyboard/mouse attached to host (or via USB passthrough)

### Start the VM
```bash
virsh start gpu-3060-gaming
```

### Expected Result
You should see the **Ubuntu installer on the physical monitor**, not inside virt-manager.

---

## Stage 5 — Identify the VM IP Address (From Host)

This method works **without logging into the VM console**.

### List running VMs
```bash
virsh list
```

### Query the VM’s network address
```bash
virsh domifaddr gpu-3060-gaming
```

### Example Output
```text
Name       MAC address          Protocol     Address
----------------------------------------------------------------
vnet0      xx:xx:xx:xx:xx:xx    ipv4         ###.###.###.###/##
```

---

## Stage 6 — In-Guest Gaming Setup (Inside VM)

Replace `###.###.###.###` with the actual VM IP.

### Copy the setup script from the host
```bash
scp ~/vms/gpu-3060-gaming-in-guest/in_guest_gaming_setup.sh user@###.###.###.###:~/
```

### Run inside the VM
```bash
bash in_guest_gaming_setup.sh
```

### Install NVIDIA Drivers
```bash
sudo ubuntu-drivers autoinstall
reboot
```

### Expected Result
- `/mnt/games` mounted and persistent
- Steam and Battle.net install to the shared game disk
- Game data survives VM rebuilds

---
