# SSH Tunnel + RDP (xRDP) via PuTTY, Pageant, and MSTSC

This guide explains how to securely access a Linux desktop over **RDP tunneled through SSH**, using **SSH key-based authentication**.

**Architecture:**
```
Windows (mstsc)
   ↓ (localhost:3390)
PuTTY SSH Tunnel (key auth)
   ↓ (SSH, port 22)
Linux Host (xRDP :3389)
```

---

## REQUIREMENTS

### Linux Host (Ubuntu 22.04+)
- OpenSSH server
- xRDP
- A desktop environment (XFCE recommended)

### Windows Client
- PuTTY
- PuTTYgen
- Pageant
- Remote Desktop Connection (mstsc)

---

## 1. SSH KEY SETUP (REQUIRED)

### 1.1 Generate SSH Key on Windows (PuTTYgen)

1. Launch **PuTTYgen**
2. Key type: **ED25519**
3. Click **Generate** and move mouse when prompted
4. Set a **key passphrase** (recommended)
5. Save:
   - **Private key** → `id_ed25519.ppk`
   - **Public key** → copy text from PuTTYgen window

---

### 1.2 Install Public Key on Linux Host

Login once using password authentication:

```bash
ssh <linux-user>@<linux-host>
```

Create SSH directory:
```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
```

Paste public key:
```bash
nano ~/.ssh/authorized_keys
```

Paste **one full line** from PuTTYgen public key box.

Set permissions:
```bash
chmod 600 ~/.ssh/authorized_keys
```

---

### 1.3 (Optional but Recommended) Disable Password SSH

```bash
sudo nano /etc/ssh/sshd_config
```

Set:
```
PasswordAuthentication no
PubkeyAuthentication yes
```

Restart SSH:
```bash
sudo systemctl restart ssh
```

---

## 2. LINUX HOST SETUP (xRDP + DESKTOP)

### 2.1 Install SSH, xRDP, and XFCE

```bash
sudo apt update
sudo apt install -y openssh-server xrdp xfce4 xfce4-goodies
```

### 2.2 Configure xRDP to use XFCE

```bash
echo "xfce4-session" > ~/.xsession
```

(Optional, system-wide default):
```bash
sudo sed -i 's|^test -x /etc/X11/Xsession && exec /etc/X11/Xsession|startxfce4|' /etc/xrdp/startwm.sh
```

### 2.3 Enable and start services

```bash
sudo systemctl enable ssh xrdp
sudo systemctl start ssh xrdp
```

Verify:
```bash
ss -tlnp | grep -E '22|3389'
```

---

## 3. FIREWALL NOTES

If `ufw` is **inactive**, no firewall changes are required.

```bash
sudo ufw status
```

If enabled, **do NOT open port 3389** when tunneling.
Only SSH (22) must be reachable.

---

## 4. WINDOWS CLIENT SETUP (Pageant + PuTTY)

### 4.1 Load Key into Pageant

1. Launch **Pageant**
2. Right-click tray icon → Add Key
3. Select `id_ed25519.ppk`
4. Enter passphrase if prompted

---

### 4.2 Configure PuTTY SSH Tunnel

1. Open **PuTTY**
2. Session:
   - Host Name: `<linux-ip-or-hostname>`
   - Port: `22`

3. Connection → SSH → Auth:
   - Ensure **Allow agent forwarding** is enabled

4. Connection → SSH → Tunnels:
   - Source port: `3390`
   - Destination: `127.0.0.1:3389`
   - Type: **Local**
   - Click **Add**

5. Save session and **Open**

Leave PuTTY running.

---

## 5. CONNECT VIA RDP (MSTSC)

1. Open **Remote Desktop Connection (mstsc)**
2. Computer:
```
localhost:3390
```
3. Username: **Linux username**
4. Password: **Linux account password** (xRDP auth)

You should now see the XFCE desktop.

---

## 6. COMMON PITFALLS

- ❌ SSH tunnel ≠ RDP server → xRDP is mandatory
- ❌ Do not open port 3389 on firewall
- ❌ Wayland sessions may fail (use XFCE / X11)
- ❌ Closing PuTTY drops the tunnel

---

## 7. QUICK DIAGNOSTICS

Linux:
```bash
systemctl status ssh xrdp
ss -tlnp | grep 3389
```

Windows:
```text
mstsc → localhost:3390
```

---

## SUMMARY

- SSH keys secure host access
- Pageant manages private keys
- PuTTY creates encrypted tunnel
- xRDP provides desktop service
- mstsc connects locally through tunnel

Only SSH is exposed to the network; RDP remains private.

