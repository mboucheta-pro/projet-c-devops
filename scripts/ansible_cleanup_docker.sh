#!/bin/bash

# Script pour nettoyer les conflits APT Docker via Ansible ad-hoc
# Usage: ./ansible_cleanup_docker.sh [jenkins_agent_ip]

set -e

JENKINS_AGENT_IP=${1:-"jenkins-agent"}

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

echo "🧹 Nettoyage Docker via Ansible ad-hoc"
echo "======================================"
echo "Target: $JENKINS_AGENT_IP"
echo

# Fonction pour exécuter des commandes Ansible
run_ansible() {
    local host="$1"
    local module="$2"
    local args="$3"
    
    ansible "$host" -m "$module" -a "$args" -b
}

log "Étape 1: Arrêt des services APT..."
run_ansible "$JENKINS_AGENT_IP" "systemd" "name=unattended-upgrades state=stopped" || true
run_ansible "$JENKINS_AGENT_IP" "systemd" "name=apt-daily state=stopped" || true

log "Étape 2: Suppression des verrous APT..."
run_ansible "$JENKINS_AGENT_IP" "file" "path=/var/lib/dpkg/lock-frontend state=absent" || true
run_ansible "$JENKINS_AGENT_IP" "file" "path=/var/lib/dpkg/lock state=absent" || true
run_ansible "$JENKINS_AGENT_IP" "file" "path=/var/lib/apt/lists/lock state=absent" || true

log "Étape 3: Suppression complète des dépôts Docker..."
# Supprimer tous les fichiers de dépôts Docker
for file in "docker.list" "docker-ce.list" "docker.sources" "docker-official.list"; do
    run_ansible "$JENKINS_AGENT_IP" "file" "path=/etc/apt/sources.list.d/$file state=absent" || true
done

# Supprimer les clés GPG Docker
for key in "docker.gpg" "docker.asc"; do
    run_ansible "$JENKINS_AGENT_IP" "file" "path=/etc/apt/trusted.gpg.d/$key state=absent" || true
    run_ansible "$JENKINS_AGENT_IP" "file" "path=/etc/apt/keyrings/$key state=absent" || true
done

log "Étape 4: Nettoyage du sources.list principal..."
run_ansible "$JENKINS_AGENT_IP" "lineinfile" "path=/etc/apt/sources.list regexp='.*docker.*' state=absent" || true

log "Étape 5: Nettoyage du cache APT..."
run_ansible "$JENKINS_AGENT_IP" "shell" "apt-get clean && rm -rf /var/lib/apt/lists/*" || true

log "Étape 6: Reconfiguration dpkg..."
run_ansible "$JENKINS_AGENT_IP" "shell" "dpkg --configure -a" || true

log "Étape 7: Première mise à jour APT..."
if run_ansible "$JENKINS_AGENT_IP" "apt" "update_cache=yes force_apt_get=yes"; then
    success "Mise à jour APT réussie"
else
    warning "Première tentative échouée, diagnostic..."
    
    # Diagnostic
    run_ansible "$JENKINS_AGENT_IP" "shell" "apt-get update 2>&1 | head -10" || true
    run_ansible "$JENKINS_AGENT_IP" "shell" "ls -la /etc/apt/sources.list.d/" || true
    
    # Supprimer les fichiers sources vides
    run_ansible "$JENKINS_AGENT_IP" "shell" "find /etc/apt/sources.list.d/ -type f -size 0 -delete" || true
    
    log "Deuxième tentative de mise à jour..."
    run_ansible "$JENKINS_AGENT_IP" "apt" "update_cache=yes force_apt_get=yes"
fi

log "Étape 8: Réinstallation propre du dépôt Docker..."

# Créer le répertoire des clés
run_ansible "$JENKINS_AGENT_IP" "file" "path=/etc/apt/keyrings state=directory mode=0755"

# Télécharger la clé GPG Docker
run_ansible "$JENKINS_AGENT_IP" "shell" "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && chmod a+r /etc/apt/keyrings/docker.gpg"

# Détecter la version Ubuntu et créer le dépôt
run_ansible "$JENKINS_AGENT_IP" "shell" "echo \"deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \$(lsb_release -cs) stable\" > /etc/apt/sources.list.d/docker-official.list"

log "Étape 9: Mise à jour finale et test..."
run_ansible "$JENKINS_AGENT_IP" "apt" "update_cache=yes"

# Tester que Docker est disponible
if run_ansible "$JENKINS_AGENT_IP" "shell" "apt-cache policy docker-ce | grep -q 'Candidate:'"; then
    success "Docker CE disponible pour installation"
else
    error "Docker CE non trouvé"
    exit 1
fi

log "Étape 10: Redémarrage des services..."
run_ansible "$JENKINS_AGENT_IP" "systemd" "name=unattended-upgrades state=started enabled=yes" || true

echo
success "✅ Nettoyage Ansible terminé avec succès!"
echo
echo "🚀 Vous pouvez maintenant relancer:"
echo "  ansible-playbook jenkins-agent-playbook.yml"
echo
echo "🔍 Vérification:"
echo "  ansible $JENKINS_AGENT_IP -m shell -a 'apt-cache policy docker-ce'"
