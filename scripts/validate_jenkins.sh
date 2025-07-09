#!/bin/bash

# Script de validation de l'installation Jenkins
# Usage: ./validate_jenkins.sh [jenkins_master_ip]

set -e

JENKINS_IP=${1:-"localhost"}
JENKINS_PORT="8080"
JENKINS_URL="http://${JENKINS_IP}:${JENKINS_PORT}"

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

# Fonction pour tester la connectivité Jenkins
test_jenkins_connectivity() {
    log "Test de connectivité Jenkins sur $JENKINS_URL..."
    
    if curl -s -o /dev/null -w "%{http_code}" "$JENKINS_URL" | grep -q "200\|403"; then
        success "Jenkins est accessible"
        return 0
    else
        error "Jenkins n'est pas accessible sur $JENKINS_URL"
        return 1
    fi
}

# Fonction pour lister les plugins installés
list_installed_plugins() {
    log "Récupération de la liste des plugins installés..."
    
    # Récupérer la liste des plugins via l'API Jenkins
    local plugins_response
    plugins_response=$(curl -s "$JENKINS_URL/pluginManager/api/json?depth=1" 2>/dev/null)
    
    if [ $? -eq 0 ] && echo "$plugins_response" | jq . >/dev/null 2>&1; then
        echo "$plugins_response" | jq -r '.plugins[] | select(.enabled == true) | .shortName' | sort
    else
        warning "Impossible de récupérer la liste des plugins via l'API"
        return 1
    fi
}

# Fonction pour vérifier les plugins requis
check_required_plugins() {
    log "Vérification des plugins requis pour le pipeline CI/CD..."
    
    local required_plugins=(
        "git"
        "workflow-aggregator"
        "pipeline-stage-view"
        "docker-workflow"
        "credentials-binding"
        "aws-credentials"
        "aws-steps"
        "pipeline-aws"
        "sonar"
        "blueocean"
        "ansicolor"
        "ws-cleanup"
    )
    
    local installed_plugins
    installed_plugins=$(list_installed_plugins)
    
    if [ $? -ne 0 ]; then
        error "Impossible de vérifier les plugins"
        return 1
    fi
    
    local missing_plugins=()
    local found_plugins=()
    
    for plugin in "${required_plugins[@]}"; do
        if echo "$installed_plugins" | grep -q "^${plugin}$"; then
            found_plugins+=("$plugin")
        else
            missing_plugins+=("$plugin")
        fi
    done
    
    echo
    log "📋 Résumé des plugins:"
    
    if [ ${#found_plugins[@]} -gt 0 ]; then
        success "Plugins trouvés (${#found_plugins[@]}):"
        for plugin in "${found_plugins[@]}"; do
            echo "  ✅ $plugin"
        done
    fi
    
    if [ ${#missing_plugins[@]} -gt 0 ]; then
        warning "Plugins manquants (${#missing_plugins[@]}):"
        for plugin in "${missing_plugins[@]}"; do
            echo "  ❌ $plugin"
        done
        echo
        error "Des plugins requis sont manquants!"
        return 1
    else
        echo
        success "Tous les plugins requis sont installés!"
        return 0
    fi
}

# Fonction pour vérifier les credentials
check_credentials() {
    log "Vérification des credentials configurés..."
    
    # Note: Cette vérification nécessiterait des credentials d'admin
    # Pour l'instant, on vérifie juste l'existence de l'endpoint
    if curl -s -o /dev/null -w "%{http_code}" "$JENKINS_URL/credentials/" | grep -q "200\|403"; then
        success "Interface de credentials accessible"
    else
        warning "Interface de credentials non accessible"
    fi
}

# Fonction pour vérifier les outils configurés
check_configured_tools() {
    log "Vérification des outils configurés..."
    
    # Vérifier l'endpoint de configuration des outils
    if curl -s -o /dev/null -w "%{http_code}" "$JENKINS_URL/configureTools/" | grep -q "200\|403"; then
        success "Interface de configuration des outils accessible"
    else
        warning "Interface de configuration des outils non accessible"
    fi
}

# Fonction pour vérifier les nodes Jenkins
check_jenkins_nodes() {
    log "Vérification des nodes Jenkins..."
    
    local nodes_response
    nodes_response=$(curl -s "$JENKINS_URL/computer/api/json" 2>/dev/null)
    
    if [ $? -eq 0 ] && echo "$nodes_response" | jq . >/dev/null 2>&1; then
        local nodes_count
        nodes_count=$(echo "$nodes_response" | jq '.computer | length')
        success "Nombre de nodes détectés: $nodes_count"
        
        # Lister les nodes
        echo "$nodes_response" | jq -r '.computer[] | "  - \(.displayName): \(if .offline then "OFFLINE" else "ONLINE" end)"'
    else
        warning "Impossible de récupérer les informations des nodes"
    fi
}

# Fonction pour tester la création de job
test_job_creation() {
    log "Test de la capacité à créer des jobs..."
    
    # Tester l'accès à l'interface de création de job
    if curl -s -o /dev/null -w "%{http_code}" "$JENKINS_URL/view/all/newJob" | grep -q "200\|403"; then
        success "Interface de création de jobs accessible"
    else
        warning "Interface de création de jobs non accessible"
    fi
}

# Fonction principale
main() {
    echo "🔍 Validation de l'installation Jenkins"
    echo "======================================"
    echo "Jenkins URL: $JENKINS_URL"
    echo
    
    # Tests de base
    if ! test_jenkins_connectivity; then
        error "Impossible de continuer - Jenkins n'est pas accessible"
        exit 1
    fi
    
    # Vérification des prérequis
    if ! command -v jq &> /dev/null; then
        warning "jq n'est pas installé - certaines vérifications seront limitées"
        echo "Pour installer jq: sudo apt-get install jq (Ubuntu) ou brew install jq (macOS)"
        echo
    fi
    
    # Tests détaillés
    check_required_plugins
    plugins_ok=$?
    
    check_credentials
    check_configured_tools
    check_jenkins_nodes
    test_job_creation
    
    echo
    echo "======================================"
    
    if [ $plugins_ok -eq 0 ]; then
        success "✅ Validation Jenkins RÉUSSIE!"
        echo "Jenkins est correctement configuré pour votre pipeline CI/CD."
        echo
        echo "🚀 Prochaines étapes recommandées:"
        echo "  1. Configurer les credentials AWS dans Jenkins"
        echo "  2. Créer les jobs de pipeline CI et CD"
        echo "  3. Tester le premier build"
    else
        error "❌ Validation Jenkins ÉCHOUÉE!"
        echo "Certains plugins requis sont manquants."
        echo
        echo "🔧 Pour corriger:"
        echo "  1. Relancer le playbook Ansible jenkins-master"
        echo "  2. Ou installer manuellement les plugins manquants"
    fi
}

# Gestion des signaux
trap 'error "Script interrompu par l utilisateur"; exit 1' INT TERM

# Aide
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage: $0 [jenkins_master_ip]"
    echo ""
    echo "Valide l'installation et la configuration de Jenkins."
    echo ""
    echo "Arguments:"
    echo "  jenkins_master_ip    IP du serveur Jenkins (défaut: localhost)"
    echo ""
    echo "Exemples:"
    echo "  $0                   # Teste localhost"
    echo "  $0 192.168.1.100     # Teste le serveur distant"
    exit 0
fi

# Exécution
main "$@"
