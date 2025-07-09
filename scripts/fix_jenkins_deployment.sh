#!/bin/bash

# Script de nettoyage et redéploiement Jenkins avec résolution des conflits APT
# Usage: ./fix_jenkins_deployment.sh [jenkins-master|jenkins-agent|all]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DIR="$SCRIPT_DIR/../infra/ansible"

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Fonction pour nettoyer complètement les dépôts Docker sur une machine distante
clean_docker_repos() {
    local host=$1
    log "Nettoyage complet des dépôts Docker sur $host..."
    
    ansible $host -i "$ANSIBLE_DIR/inventory" -b -m shell -a "
        # Supprimer tous les fichiers de dépôts Docker
        rm -f /etc/apt/sources.list.d/docker*.list
        rm -f /etc/apt/sources.list.d/docker*.sources
        rm -f /etc/apt/trusted.gpg.d/docker*
        rm -f /etc/apt/keyrings/docker*
        
        # Nettoyer les références Docker du sources.list principal
        sed -i '/docker/d' /etc/apt/sources.list
        
        # Forcer la mise à jour du cache APT
        apt-get clean
        rm -rf /var/lib/apt/lists/*
        apt-get update
    " || warning "Nettoyage partiel sur $host"
}

# Fonction pour vérifier les prérequis
check_prerequisites() {
    log "Vérification des prérequis..."
    
    if ! command -v ansible &> /dev/null; then
        error "Ansible n'est pas installé"
        exit 1
    fi
    
    if ! command -v ansible-playbook &> /dev/null; then
        error "ansible-playbook n'est pas installé"
        exit 1
    fi
    
    if [ ! -f "$ANSIBLE_DIR/inventory" ]; then
        error "Fichier d'inventaire non trouvé: $ANSIBLE_DIR/inventory"
        exit 1
    fi
    
    success "Prérequis OK"
}

# Fonction pour déployer Jenkins Master
deploy_jenkins_master() {
    log "Déploiement de Jenkins Master..."
    
    # Nettoyer d'abord les dépôts Docker
    clean_docker_repos "jenkins"
    
    # Exécuter le playbook Jenkins master
    cd "$ANSIBLE_DIR"
    ansible-playbook -i inventory jenkins-master-playbook.yml \
        --extra-vars "ansible_ssh_common_args='-o StrictHostKeyChecking=no'" \
        -v
    
    success "Jenkins Master déployé avec succès"
}

# Fonction pour déployer Jenkins Agent
deploy_jenkins_agent() {
    log "Déploiement de Jenkins Agent..."
    
    # Nettoyer d'abord les dépôts Docker
    clean_docker_repos "jenkins_agents"
    
    # Exécuter le playbook Jenkins agent
    cd "$ANSIBLE_DIR"
    ansible-playbook -i inventory jenkins-agent-playbook.yml \
        --extra-vars "ansible_ssh_common_args='-o StrictHostKeyChecking=no'" \
        -v
    
    success "Jenkins Agent déployé avec succès"
}

# Fonction pour valider l'installation
validate_installation() {
    local host=$1
    log "Validation de l'installation sur $host..."
    
    ansible $host -i "$ANSIBLE_DIR/inventory" -m shell -a "
        echo '=== Versions des outils installés ==='
        docker --version 2>/dev/null || echo 'Docker: NON INSTALLÉ'
        java -version 2>&1 | head -n1 || echo 'Java: NON INSTALLÉ'
        node --version 2>/dev/null || echo 'Node.js: NON INSTALLÉ'
        npm --version 2>/dev/null || echo 'npm: NON INSTALLÉ'
        aws --version 2>/dev/null || echo 'AWS CLI: NON INSTALLÉ'
        terraform version 2>/dev/null | head -n1 || echo 'Terraform: NON INSTALLÉ'
        kubectl version --client 2>/dev/null | head -n1 || echo 'kubectl: NON INSTALLÉ'
        trivy --version 2>/dev/null || echo 'Trivy: NON INSTALLÉ'
        
        echo '=== État des services ==='
        systemctl is-active docker 2>/dev/null || echo 'Docker service: INACTIF'
        systemctl is-active jenkins 2>/dev/null || echo 'Jenkins service: INACTIF'
    "
}

# Fonction principale
main() {
    local action=${1:-"all"}
    
    check_prerequisites
    
    case $action in
        "jenkins-master")
            deploy_jenkins_master
            validate_installation "jenkins"
            ;;
        "jenkins-agent")
            deploy_jenkins_agent
            validate_installation "jenkins_agents"
            ;;
        "all")
            deploy_jenkins_master
            sleep 30  # Attendre que Jenkins Master soit prêt
            deploy_jenkins_agent
            validate_installation "jenkins"
            validate_installation "jenkins_agents"
            ;;
        *)
            error "Action non reconnue: $action"
            echo "Usage: $0 [jenkins-master|jenkins-agent|all]"
            exit 1
            ;;
    esac
    
    success "Déploiement terminé avec succès!"
    log "Jenkins devrait être accessible sur: http://\$(jenkins_master_ip):8080"
}

# Gestion des signaux
trap 'error "Script interrompu par l utilisateur"; exit 1' INT TERM

# Exécution
main "$@"
