# VM-Box — Ansible-Driven Local VM Infrastructure

This repository manages a **local virtualization host** using **Ansible**, with:
- A clean base hypervisor setup
- A reusable RTX 3060 gaming VM
- A shared game data disk
- Clear separation between host, VM, and in-guest steps

All Ansible runs are **local** (this machine is both controller and target).

---

## Stage 1 — Install Ansible (Local Controller)

### Command
```bash
bash setup/setup_ansible.sh
```

### Expected Result
- Ansible installs successfully
- `ansible --version` prints without errors

---

## Stage 2 — Base VM / Hypervisor Setup

This stage converts the machine into a **KVM/libvirt hypervisor**.

### Command
```bash
ansible-playbook vm_setup/base_vm_setup.yml
```

### Expected Result
- libvirt running
- virt-manager launches
- `~/vms` directory exists
- No VMs created yet

**Reboot recommended after this step.**

---

## Stage 3 — RTX 3060 Gaming VM (Definition Only)

This stage defines the gaming VM and attaches disks.

### Command
```bash
ansible-playbook gaming/3060/ansible/create_3060_gaming_vm.yml
```

### Expected Result
- Gaming VM appears in virt-manager
- Shared game disk attached
- In-guest setup script staged and path printed

---

## Stage 4 — GPU Passthrough (Host Action)

Run on the host:

```bash
bash scripts/gpu_passthrough_config.sh
```

### Expected Result
- RTX 3060 GPU and HDMI audio PCI IDs detected
- Clear virt-manager instructions printed

---

### Stage 5 — Identify the VM IP Address From the host using libvirt

This method allows you to determine the VM’s IP address **from the host**, without logging into the VM console.

**List running VMs:**
```bash
virsh list
```

**Query the VM’s network address:**
```bash
virsh domifaddr gpu-3060-gaming
```

**Example output:**
```text
Name       MAC address          Protocol     Address
----------------------------------------------------------------
vnet0      xx:xx:xx:xx:xx:xx    ipv4         ###.###.###.###/##
```


## Stage 6 — In-Guest Gaming Setup (Inside VM)

**Use:** `###.###.###.###` (replace actual IP you found)

This command works **only after the VM has booted** and obtained an IP address via DHCP (default libvirt NAT network).

You can now transfer the in-guest setup script using:
```bash
scp ~/vms/gpu-3060-gaming-in-guest/in_guest_gaming_setup.sh user@###.###.###.###:~/
```

### Run Inside VM
```bash
bash in_guest_gaming_setup.sh
```

### Expected Result
- /mnt/games mounted
- Steam and Battle.net install to shared game disk
- Game data persists across VM rebuilds

---