# Remove Virtual Graphics (Required for GPU Passthrough)

This step is **mandatory** when using PCI GPU passthrough.  
The virtual GPU (**Video Virtio**) must be removed from the VM definition.

---

## Remove Virtual Graphics

### Step 1 — Ensure VM is Powered Off

```bash
virsh list --all
```

Confirm the VM shows **shut off**:
```text
gpu-3060-gaming   shut off
```

If needed:
```bash
virsh shutdown gpu-3060-gaming
```

---

### Step 2 — Edit the VM XML

```bash
virsh edit gpu-3060-gaming
```

---

### Step 3 — Delete the Virtual Video Device

**Delete this entire block exactly as shown:**

```xml
<video>
  <model type='virtio' heads='1' primary='yes'/>
  <address type='pci' domain='0x0000' bus='0x00' slot='0x01' function='0x0'/>
</video>
```

⚠️ **Delete the full `<video>...</video>` block. Do not leave any part behind.**

---

### Step 4 — Delete the Graphics Display (If Present)

Also delete **any** `<graphics>` block, such as:

```xml
<graphics type='spice' autoport='yes'/>
```

or

```xml
<graphics type='vnc'/>
```

---

### Step 5 — Save and Exit

- Press **CTRL + O** → Enter  
- Press **CTRL + X**

libvirt will automatically validate the XML.

---

### Step 6 — Verify Removal

```bash
virsh dumpxml gpu-3060-gaming | grep -E '<video>|<graphics>'
```

**Expected output:**  
➡️ *(no output)*

---

## Result

- Virtual GPU fully removed
- virt-manager display will be black (expected)
- Video output will come **only** from the RTX 3060
- VM is ready to boot with GPU passthrough

---
