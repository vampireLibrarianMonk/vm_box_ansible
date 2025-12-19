# 0. OpenSSH Server Setup

## Install OpenSSH server and other networking software
```bash
sudo apt-get update
sudo apt-get install -y openssh-server curl
```

## Enable and start SSH service
```bash
sudo systemctl enable --now ssh
```

## Diagnostic: confirm SSH is listening on port 22
```bash
echo "  - Verifying SSH is listening on port 22:"
ss -tlnp | grep ':22' || echo "WARNING: SSH is not listening on port 22"
```

## Final: Restart VM