# Enable AMD-V (SVM) — ASUS TUF B550M-PLUS WiFi II

This README documents the **required BIOS change** to enable hardware virtualization for KVM, libvirt, and GPU passthrough.

---

## Steps

1. **Reboot** the system  
2. During boot, press **DEL** or **F2** to enter BIOS
3. Press **F7** to switch to **Advanced Mode**
4. Navigate to:

```
Advanced → CPU Configuration → SVM Mode
```

5. Set **SVM Mode = Enabled**
6. Press **F10**, confirm **Yes**, and reboot

---

## Verify in Ubuntu

After reboot, run:

```bash
lscpu | grep Virtualization
```

### Expected Output
```text
Virtualization: AMD-V
```

Verify KVM device exists:

```bash
ls -l /dev/kvm
```

### Expected Output
```text
crw-rw----+ 1 root kvm ... /dev/kvm
```

---

## Result

- KVM acceleration enabled
- virt-manager supports `virt-type=kvm`
- PCI passthrough (RTX 3060) works
- Resolves: **“Emulator does not support virt type kvm”**

---

✅ One-time BIOS change. No OS reinstall required.
