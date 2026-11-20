#!/bin/bash
set -e
sudo apt update && sudo apt upgrade -y
sudo apt install -y nginx ufw
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw --force enable
sudo systemctl enable --now nginx
echo "Setup complete"
