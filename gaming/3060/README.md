# RTX 3060 Passthrough Gaming VM — Step-by-Step Guide

This document describes the **exact, validated sequence** to bring up the RTX 3060 passthrough gaming VM.

---

## Stage 1 — RTX 3060 Gaming VM (Definition Only)

This stage defines the gaming VM and attaches disks.  
**No GPU is attached yet.**

### Command
```bash
ansible-playbook gaming/3060/ansible/create_3060_gaming_vm.yml \
  --tags create,postcheck \
  --skip-tags destroy \
  --ask-become-pass
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

Open **virt-manager** → select **gpu-3060-gaming** → **Open** → **View Details**

---

#### Add PCI Devices
- Click **Add Hardware**
- Select **PCI Host Device**
- Add **both** devices:
  - `01:00.0` → **NVIDIA RTX 3060 GPU**
  - `01:00.1` → **NVIDIA HDMI Audio**
- Ensure you add **keyboard** and **mouse** via either
  - USB
  - PS2

> ⚠️ Both devices must be added or audio will not work and the GPU may fail to initialize.
> ⚠️ Mouse and keyboard are necessary to do things.
---

#### Firmware (Verify)
- Confirm **Firmware** is set to:
  - **UEFI (OVMF)**
- If not:
  - Change firmware to **UEFI**
  - Save, then re-open the VM details to confirm

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

### CPU Pinning

CPU pinning is applied after the VM starts so each virtual CPU is permanently bound to a specific physical core, preventing scheduler migration, cache thrashing, and latency spikes that severely hurt single-thread-heavy games like StarCraft II.

Run inside the guest:

```bash
lscpu | egrep 'CPU\(s\)|Thread|Core|Socket'
```

You must see:
```bash
CPU(s):                8
Thread(s) per core:    1
Core(s) per socket:    8
Socket(s):             1
```

Now run each time you start up the vm:
```bash
for i in {0..7}; do sudo virsh vcpupin gpu-3060-gaming "$i" "$i"; done
virsh vcpupin gpu-3060-gamingvirsh vcpupin gpu-3060-gaming
```

Expected:
```bash
VCPU  CPU Affinity
0     0
1     1
2     2
3     3
4     4
5     5
6     6
7     7
```

The follow the initial setup of ubuntu 22.04.5 [here](setup/Initial_Ubuntu_22_04_05_Setup.md)

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

### Use the following to scp files to the vm
```bash
scp {FULL_FILE_PATH} user@###.###.###.###:~/
```

The following markdowns will setup your vm for battlenet and starcraft 2.
- gaming/01_openssh.md
- gaming/02_gamedisk_mounts.md
- gaming/03_nvidia_driver.md
- gaming/04_gaming_packages.md
- gaming/05_wine_drive.md
- gaming/06_battlenet.md

## Stage 8 — VM Teardown — Destroy libvirt VM (UEFI / OVMF)

Use this stage to completely remove the VM created by:

```bash
ansible-playbook gaming/3060/ansible/create_3060_gaming_vm.yml \
  --tags destroy \
  --ask-become-pass
```

Replace `gpu-3060-gaming` if your VM name differs.

---

### Stop the VM (if running)
```bash
virsh destroy gpu-3060-gaming
```

---

### Undefine the VM (required for UEFI / OVMF)
```bash
virsh undefine gpu-3060-gaming --nvram
```

---

### Optional: Remove VM disk files
Only run these if you want to permanently delete the VM storage.
```bash
rm -f /path/to/os_disk.qcow2
rm -f /path/to/game_disk.qcow2
```

---

### One-Line Cleanup (Safe)
```bash
virsh destroy gpu-3060-gaming || true && virsh undefine gpu-3060-gaming --nvram
```

---

### Verify Removal
```bash
virsh list --all
```

Expected result: `gpu-3060-gaming` is no longer listed.

