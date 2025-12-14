#!/usr/bin/env bash
set -Eeuo pipefail

echo "=== In-Guest Gaming VM Setup ==="

echo "[1] Creating /mnt/games and mounting second disk..."
sudo mkdir -p /mnt/games

# Add fstab entry if missing
if ! grep -q "/mnt/games" /etc/fstab; then
    echo "/dev/vdb /mnt/games ext4 defaults 0 2" | sudo tee -a /etc/fstab
fi

sudo mount -a

echo "[2] Enabling 32-bit architecture and installing Wine stack..."
sudo dpkg --add-architecture i386
sudo apt update
sudo apt install -y \
    wine64 wine32 winetricks \
    lutris steam \
    libvulkan1 libvulkan1:i386

echo "[3] Creating recommended game folders..."
mkdir -p ~/Games
mkdir -p /mnt/games/BattleNet
mkdir -p /mnt/games/SC2
mkdir -p /mnt/games/SteamLibrary

echo ""
echo "=== In-Guest Setup Complete ==="
echo "Battle.net install path:       /mnt/games/BattleNet"
echo "StarCraft II install path:     /mnt/games/SC2"
echo "Steam Library:                 /mnt/games/SteamLibrary"
echo ""
echo "Next: Install Battle.net through Lutris and point everything to /mnt/games."
