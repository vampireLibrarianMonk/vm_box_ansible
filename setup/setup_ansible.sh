#!/usr/bin/env bash
set -Eeuo pipefail

###############################################################################
# Ansible Setup Script (Ubuntu 22.04+)
#
# This script:
#   - Installs Ansible from the official Ubuntu repository
#   - Installs recommended supporting tools
#   - Creates an Ansible working directory
#   - Generates a starter inventory file and ansible.cfg
#
# Run with:
#   bash setup_ansible.sh
###############################################################################

echo "=== Installing Ansible and prerequisites ==="

# Update package index
sudo apt update

# Install Ansible + supporting tools
sudo apt install -y \
    ansible \
    python3-venv \
    python3-pip \
    sshpass

echo "=== Creating Ansible working directory ==="

# Default Ansible workspace
ANSIBLE_DIR="$HOME/ansible"
mkdir -p "$ANSIBLE_DIR"

# Create inventory directory
mkdir -p "$ANSIBLE_DIR/inventory"

# Starter inventory file (localhost execution)
cat << 'EOF' > "$ANSIBLE_DIR/inventory/hosts"
[local]
localhost ansible_connection=local
EOF

echo "=== Writing ansible.cfg ==="

cat << 'EOF' > "$ANSIBLE_DIR/ansible.cfg"
[defaults]
inventory = ./inventory/hosts
host_key_checking = False
retry_files_enabled = False
forks = 10

[privilege_escalation]
become = True
become_method = sudo
EOF

echo "=== Validating Installation ==="

ansible --version

echo ""
echo "=== Setup Complete ==="
echo "Your Ansible workspace is ready at: $ANSIBLE_DIR"
echo "Run a test with:"
echo "  cd $ANSIBLE_DIR && ansible all -m ping"
