## Stage 1 — RTX 3060 Gaming VM (Definition Only)

This stage defines the gaming VM and attaches disks.

### Command
```bash
ansible-playbook gaming/3060/ansible/create_3060_gaming_vm.yml --ask-become-pass
```

### Expected Result
- Gaming VM appears in virt-manager
- Shared game disk attached
- In-guest setup script staged and path printed

---

## Stage 2 — GPU Passthrough (Host Action)

Run on the host:

```bash
bash scripts/gpu_passthrough_config.sh
```

### Expected Result
- RTX 3060 GPU and HDMI audio PCI IDs detected
- Clear virt-manager instructions printed

---

### Stage 3 — Identify the VM IP Address From the host using libvirt

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

## Stage 4 — In-Guest Gaming Setup (Inside VM)

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