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
ansible-playbook vm_setup/base_vm_setup.yml \
  --ask-become-pass

```

### Post Check
```bash
ansible-playbook vm_setup/base_vm_setup.yml \
  --tags postcheck \
  --ask-become-pass
```

### Expected Output:
```bash
TASK [postcheck : POSTCHECK | Success summary] 
ok: [localhost] => 
  msg:
  - libvirt running and enabled
  - virt-manager installed
  - KVM acceleration available
  - VM storage directory exists and empty
  - No libvirt VMs defined
  - System ready for VM creation
  - Reboot recommended
```

---