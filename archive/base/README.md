# Base VM Infrastructure — Quick Setup

This directory contains the **base environment setup** for creating all future VMs:

This README assumes you will use the included setup script.

---

## 1. Run the Base Setup Script

Execute the script in this directory to install all required virtualization components and prepare the system:

```bash
./setup_base_vm_infra.sh
```

This script:

- Installs the minimal virtualization stack  
- Enables libvirt and configures user permissions  
- Creates the `~/vms` directory for VM storage  

See the script itself for package-by-package explanations.

---

## 2. Reboot

A reboot is required before creating any VMs:

```bash
sudo reboot
```

---

## 3. After Reboot — Create Your VM Templates

Once the base infrastructure is installed and the system has rebooted, you may proceed to create your individual VMs. Each of these VMs will rely on the environment prepared by the script above.

---