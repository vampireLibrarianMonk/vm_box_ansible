# SSH Tunnel + RDP (xRDP) via PuTTY, Pageant, and MSTSC

This guide explains how to securely access a Linux desktop over **RDP tunneled through SSH**, using **SSH key-based authentication**.

---

## Architecture

```
Windows (mstsc)
   ↓ (localhost:3390)
PuTTY SSH Tunnel (key auth)
   ↓ (SSH, port 22)
Linux Host (xRDP :3389)
```

**Key principle:**  
Only **SSH (22)** is exposed to the network.  
**RDP (3389)** is never exposed directly.

---

## REQUIREMENTS

### Linux Host (Ubuntu 22.04+)
- OpenSSH server
- xRDP
- Desktop environment (XFCE recommended)
- User account with sudo

### Windows Client
- PuTTY
- PuTTYgen
- Pageant
- Remote Desktop Connection (`mstsc`)

---

## 1. LINUX HOST BASE SETUP (DO THIS FIRST)

### 1.1 Install SSH, xRDP, and XFCE

```bash
sudo apt update
sudo apt install -y openssh-server xrdp xfce4 xfce4-goodies
```

---

### 1.2 Enable and start required services

```bash
sudo systemctl enable ssh
sudo systemctl enable xrdp
sudo systemctl start ssh
sudo systemctl start xrdp
```

Verify:
```bash
ss -tlnp | grep -E '22|3389'
```

---

### 1.3 Configure xRDP to use XFCE (required)

Per-user session:
```bash
echo "xfce4-session" > ~/.xsession
```

(Optional, system-wide default):
```bash
sudo sed -i 's|^test -x /etc/X11/Xsession && exec /etc/X11/Xsession|startxfce4|' /etc/xrdp/startwm.sh
```

Restart xRDP:
```bash
sudo systemctl restart xrdp
```

---

## 2. SSH KEY SETUP (REQUIRED)

### 2.1 Generate SSH Key on Windows (PuTTYgen)

1. Launch **PuTTYgen**
2. Key type: **ED25519**
3. Click **Generate**
4. Set a **key passphrase**
5. Save:
   - Private key → `id_ed25519.ppk`
   - Public key → copy from PuTTYgen window
   - Load the public key into its own line in the server's authorized_keys

---

## 3. WINDOWS CLIENT SETUP

### 3.1 Load SSH Key into Pageant

1. Launch **Pageant**
2. Add key: `id_ed25519.ppk`
3. Enter passphrase

---

### 3.2 Configure PuTTY SSH Tunnel

**Session**
- Host Name: `<linux-ip-or-hostname>`
- Port: `22`

**Connection → SSH → Auth**
- Enable agent forwarding

**Connection → SSH → Tunnels**
- Source port: `3390`
- Destination: `127.0.0.1:3389`
- Type: Local
- Click **Add**

Save session → **Open**

Leave PuTTY running.

---

## 4. CONNECT VIA RDP (MSTSC)

1. Open **Remote Desktop Connection**
2. Computer:
```
localhost:3390
```
3. Login with Linux username/password

You should see the **XFCE desktop**.

---

## 5. COMMON PITFALLS

- SSH tunnel alone does not provide a desktop
- Do not expose port 3389
- Avoid Wayland desktops
- Closing PuTTY closes the tunnel
- Pageant must be running

---

## 7. QUICK DIAGNOSTICS

Linux:
```bash
systemctl status ssh xrdp
ss -tlnp | grep 3389
```

Windows:
```
mstsc → localhost:3390
```

---

## SUMMARY

- SSH keys secure access
- Pageant manages keys
- PuTTY provides encrypted tunnel
- xRDP serves desktop
- mstsc connects locally

Only SSH is exposed; RDP remains private.
