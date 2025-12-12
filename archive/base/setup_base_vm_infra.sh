#!/usr/bin/env bash
set -Eeuo pipefail

echo "=== Base VM Infrastructure Setup ==="

echo "[1] Installing virtualization packages..."
sudo apt update

# QEMU KVM hypervisor (core virtualization engine)
sudo apt install -y qemu-kvm

# Libvirt system daemon (manages VMs, networks, storage)
sudo apt install -y libvirt-daemon-system

# Libvirt client tools (virsh, virt-* utilities)
sudo apt install -y libvirt-clients

# Virt-manager GUI (interactive VM creation & management)
sudo apt install -y virt-manager

# OVMF UEFI firmware (required for modern UEFI VM boot)
sudo apt install -y ovmf

# Bridge utilities (support for bridged networking & custom networks)
sudo apt install -y bridge-utils

# PCI device utilities (lspci—needed for passthrough identification)
sudo apt install -y pciutils

# USB utilities (lsusb—required for CAC reader passthrough)
sudo apt install -y usbutils


echo "[2] Enabling libvirt..."
sudo systemctl enable --now libvirtd

echo "[3] Adding user to virtualization groups..."
sudo usermod -aG libvirt,libvirt-qemu "$USER"

echo "[4] Creating VM storage directory..."
mkdir -p "$HOME/vms"

echo "=== Base VM Infrastructure Setup Complete ==="
echo "REBOOT recommended before creating VMs."
