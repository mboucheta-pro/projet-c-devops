#!/bin/bash
# Solution radicale pour les conflits Docker APT
set -e

echo "🧹 Nettoyage radical Docker APT..."

# Arrêter APT services
systemctl stop unattended-upgrades apt-daily apt-daily-upgrade 2>/dev/null || true

# Supprimer TOUS les fichiers Docker APT
rm -rf /etc/apt/sources.list.d/*docker*
rm -rf /etc/apt/trusted.gpg.d/*docker*
rm -rf /etc/apt/keyrings/*docker*
sed -i '/docker/d' /etc/apt/sources.list

# Nettoyer cache
apt-get clean
rm -rf /var/lib/apt/lists/*

# Recréer proprement
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

# Test
apt-get update
echo "✅ Docker APT fixé"
