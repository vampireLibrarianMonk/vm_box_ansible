## Ubuntu Installer Boot (UEFI / OVMF) — Screen-by-Screen Directions

Use these steps when the VM boots into the UEFI menus shown.

---

### 1. UEFI Interactive Shell
If you see **UEFI Interactive Shell v2.2**:

- Type **Exit**
- Press **Enter**

This will automatically exit the shell and return to the UEFI menu.

---

### 2. UEFI Main Menu
At the **Standard PC (Q35 + ICH9)** menu:

- Select **Boot Manager**
- Press **Enter**

---

### 3. Boot Manager Menu
In **Boot Manager Menu**:

- Select **UEFI QEMU DVD-ROM QM00001**
  - This is the attached Ubuntu ISO
- Press **Enter**

⚠️ Do **not** select PXE or EFI Shell options.

---

### 4. GNU GRUB (Ubuntu Installer)
At the **GNU GRUB 2.06** screen:

- Leave **Try or Install Ubuntu** highlighted
- Press **Enter**

Optional fallback:
- If you get a black screen later, reboot and select:
  - **Ubuntu (safe graphics)**

---

### 5. Ubuntu Installer
You are now in the Ubuntu installer.

Proceed normally:
- Language
- Keyboard
- Network
- Install Ubuntu

---

### Notes
- This flow is **normal for UEFI + GPU passthrough**
- Seeing the UEFI Shell is expected on first boot
- After installation completes, **remove the ISO** when prompted and reboot

---
