#!/bin/bash

# Script de vérification des services SonarQube
# Usage: ./check-sonarqube-services.sh

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

echo "🔍 Vérification des services SonarQube"
echo "======================================"

# Vérification Docker
log "Vérification du service Docker..."
if systemctl is-active --quiet docker; then
    success "Docker est actif"
else
    error "Docker n'est pas actif"
    exit 1
fi

# Vérification des containers SonarQube
log "Vérification des containers SonarQube..."
echo
echo "📋 Containers Docker:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(NAMES|sonar)" || echo "Aucun container SonarQube trouvé"
echo

# Vérification du container SonarQube spécifique
if docker ps --format "{{.Names}}" | grep -q "sonarqube"; then
    success "Container SonarQube en cours d'exécution"
    
    # Logs récents
    log "Logs récents SonarQube (20 dernières lignes):"
    echo "----------------------------------------"
    docker logs --tail 20 sonarqube 2>/dev/null | tail -10
    echo "----------------------------------------"
else
    warning "Container SonarQube non trouvé ou arrêté"
    
    # Vérifier si le container existe mais est arrêté
    if docker ps -a --format "{{.Names}}" | grep -q "sonarqube"; then
        warning "Container SonarQube trouvé mais arrêté"
        log "Tentative de démarrage..."
        docker start sonarqube || error "Impossible de démarrer le container"
    fi
fi

echo

# Test de connectivité HTTP
log "Test de connectivité SonarQube..."
response_code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9000 2>/dev/null || echo "000")

case $response_code in
    "200")
        success "SonarQube est accessible (HTTP 200)"
        ;;
    "000")
        error "Impossible de se connecter à SonarQube (connexion refusée)"
        ;;
    *)
        warning "SonarQube répond avec le code HTTP: $response_code"
        ;;
esac

# Test de l'API SonarQube
log "Test de l'API SonarQube..."
if command -v jq &> /dev/null; then
    api_response=$(curl -s http://localhost:9000/api/system/status 2>/dev/null)
    if echo "$api_response" | jq . >/dev/null 2>&1; then
        echo "📊 Statut de l'API SonarQube:"
        echo "$api_response" | jq .
        success "API SonarQube opérationnelle"
    else
        warning "Réponse API non valide ou SonarQube en cours de démarrage"
        echo "Réponse brute: $api_response"
    fi
else
    warning "jq non installé - test de l'API avec curl uniquement"
    api_response=$(curl -s http://localhost:9000/api/system/status 2>/dev/null)
    if [[ "$api_response" == *"status"* ]]; then
        success "API SonarQube semble répondre"
        echo "Réponse: $api_response"
    else
        warning "API SonarQube ne répond pas correctement"
    fi
fi

echo

# Vérification des ports
log "Vérification des ports..."
if netstat -tuln 2>/dev/null | grep -q ":9000"; then
    success "Port 9000 en écoute"
else
    if command -v ss &> /dev/null; then
        if ss -tuln | grep -q ":9000"; then
            success "Port 9000 en écoute (ss)"
        else
            error "Port 9000 non en écoute"
        fi
    else
        warning "Impossible de vérifier les ports (netstat/ss non disponible)"
    fi
fi

# Vérification de l'espace disque
log "Vérification de l'espace disque..."
disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$disk_usage" -lt 90 ]; then
    success "Espace disque OK ($disk_usage% utilisé)"
else
    warning "Espace disque critique ($disk_usage% utilisé)"
fi

# Vérification de la mémoire
log "Vérification de la mémoire..."
if command -v free &> /dev/null; then
    memory_info=$(free -h | grep "Mem:")
    echo "💾 Mémoire: $memory_info"
else
    warning "Commande 'free' non disponible"
fi

echo
echo "======================================"

# Résumé final
if [ "$response_code" = "200" ]; then
    success "✅ SonarQube est opérationnel!"
    echo
    echo "🌐 Accès Web: http://$(hostname -I | awk '{print $1}'):9000"
    echo "🔑 Identifiants par défaut: admin/admin"
    echo
    echo "🚀 Prochaines étapes:"
    echo "  1. Changer le mot de passe admin par défaut"
    echo "  2. Configurer l'intégration avec Jenkins"
    echo "  3. Créer les projets et quality gates"
else
    error "❌ SonarQube n'est pas accessible"
    echo
    echo "🔧 Actions de dépannage:"
    echo "  1. Vérifier les logs: docker logs sonarqube"
    echo "  2. Redémarrer: docker restart sonarqube"
    echo "  3. Vérifier la configuration dans docker-compose.yml"
fi
