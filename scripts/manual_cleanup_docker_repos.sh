#!/bin/bash

# Script de nettoyage manuel des conflits APT Docker
# À exécuter directement sur le serveur avec sudo
# Usage: sudo ./manual_cleanup_docker_repos.sh

set -e

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[✅]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[⚠️ ]${NC} $1"
}

error() {
    echo -e "${RED}[❌]${NC} $1"
}

# Vérifier les privilèges root
if [[ $EUID -ne 0 ]]; then
   error "Ce script doit être exécuté avec sudo"
   exit 1
fi

echo "🧹 Nettoyage complet des dépôts Docker"
echo "====================================="
echo

log "Arrêt des processus APT en cours..."
# Arrêter les processus qui pourraient verrouiller APT
systemctl stop unattended-upgrades.service 2>/dev/null || true
systemctl stop apt-daily.service 2>/dev/null || true
systemctl stop apt-daily-upgrade.service 2>/dev/null || true

log "Attente de la libération des verrous APT..."
# Attendre que tous les processus APT se terminent
while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
    echo "Attente de la libération du verrou APT..."
    sleep 2
done

log "Suppression des verrous APT..."
# Supprimer tous les verrous
rm -f /var/lib/dpkg/lock-frontend
rm -f /var/lib/dpkg/lock
rm -f /var/lib/apt/lists/lock
rm -f /var/cache/apt/archives/lock

log "Nettoyage complet des dépôts Docker..."
# Supprimer TOUS les fichiers de dépôts Docker
rm -f /etc/apt/sources.list.d/docker*.list
rm -f /etc/apt/sources.list.d/docker*.sources
rm -f /etc/apt/trusted.gpg.d/docker*
rm -f /etc/apt/keyrings/docker*

log "Nettoyage des dépôts Trivy..."
# Supprimer les dépôts Trivy aussi
rm -f /etc/apt/sources.list.d/trivy*.list
rm -f /usr/share/keyrings/trivy*

log "Nettoyage du sources.list principal..."
# Supprimer les références Docker du sources.list principal
sed -i '/docker/d' /etc/apt/sources.list
sed -i '/trivy/d' /etc/apt/sources.list

log "Nettoyage du cache APT..."
# Nettoyer complètement le cache APT
apt-get clean
rm -rf /var/lib/apt/lists/*
rm -rf /var/cache/apt/archives/partial/*

log "Reconfiguration de dpkg..."
# Reconfigurer dpkg en cas de problème
dpkg --configure -a

log "Première tentative de mise à jour APT..."
# Première tentative de mise à jour
if apt-get update; then
    success "Mise à jour APT réussie"
else
    warning "Première tentative échouée, diagnostic..."
    
    # Diagnostic des erreurs restantes
    echo "=== Diagnostic des erreurs APT ==="
    apt-get update 2>&1 | head -20
    
    echo "=== Contenu de sources.list.d ==="
    ls -la /etc/apt/sources.list.d/
    
    # Supprimer les fichiers sources vides ou corrompus
    find /etc/apt/sources.list.d/ -type f -size 0 -delete
    
    # Deuxième tentative
    log "Deuxième tentative de mise à jour..."
    apt-get update
fi

log "Installation propre des dépôts Docker..."
# Réinstaller Docker proprement

# Créer le répertoire des clés
mkdir -p /etc/apt/keyrings

# Télécharger la clé GPG Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Détecter la version Ubuntu
UBUNTU_CODENAME=$(lsb_release -cs)
echo "Version Ubuntu détectée: $UBUNTU_CODENAME"

# Créer le fichier de dépôt Docker propre
cat > /etc/apt/sources.list.d/docker-official.list << EOF
deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $UBUNTU_CODENAME stable
EOF

log "Mise à jour finale..."
apt-get update

log "Test d'installation Docker..."
# Tester que Docker peut être trouvé
if apt-cache policy docker-ce | grep -q "Candidate:"; then
    success "Docker CE disponible pour installation"
else
    error "Docker CE non trouvé dans les dépôts"
    exit 1
fi

log "Redémarrage des services APT..."
# Redémarrer les services
systemctl start unattended-upgrades.service 2>/dev/null || true

echo
success "✅ Nettoyage terminé avec succès!"
echo
echo "🚀 Prochaines étapes:"
echo "  1. Relancer le playbook Jenkins agent: ansible-playbook jenkins-agent-playbook.yml"
echo "  2. Ou installer Docker manuellement: apt-get install docker-ce docker-ce-cli containerd.io"
echo
echo "🔍 Vérification:"
echo "  - Sources Docker: cat /etc/apt/sources.list.d/docker-official.list"
echo "  - Clé GPG: ls -la /etc/apt/keyrings/docker.gpg"
echo "  - Test APT: apt-cache policy docker-ce"
