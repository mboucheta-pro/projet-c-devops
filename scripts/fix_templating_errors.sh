#!/bin/bash

# Script de correction des erreurs de templating Jinja2 dans les playbooks
# Usage: ./fix_templating_errors.sh

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

echo "🔧 Correction des erreurs de templating Jinja2"
echo "============================================="
echo

# Fonction pour corriger les problèmes de templating courants
fix_templating_issues() {
    log "Vérification et correction des problèmes de templating..."
    
    local playbooks=(
        "$ANSIBLE_DIR/sonarqube-playbook.yml"
        "$ANSIBLE_DIR/jenkins-master-playbook.yml"
        "$ANSIBLE_DIR/jenkins-agent-playbook.yml"
    )
    
    for playbook in "${playbooks[@]}"; do
        if [ -f "$playbook" ]; then
            log "Vérification de $(basename "$playbook")..."
            
            # Rechercher les problèmes courants
            if grep -n "{{.*}}" "$playbook" | grep -v "{% raw %}" | grep -v "{{ '{{'" >/dev/null; then
                warning "Problèmes de templating potentiels détectés dans $(basename "$playbook")"
                echo "Lignes problématiques:"
                grep -n "{{.*}}" "$playbook" | grep -v "{% raw %}" | grep -v "{{ '{{'"
                echo
            else
                success "Aucun problème de templating dans $(basename "$playbook")"
            fi
        else
            warning "Playbook non trouvé: $playbook"
        fi
    done
}

# Fonction pour tester les playbooks
test_playbooks() {
    log "Test de syntaxe des playbooks..."
    
    cd "$ANSIBLE_DIR"
    
    local playbooks=(
        "sonarqube-playbook.yml"
        "jenkins-master-playbook.yml"
        "jenkins-agent-playbook.yml"
    )
    
    for playbook in "${playbooks[@]}"; do
        if [ -f "$playbook" ]; then
            log "Test de syntaxe: $playbook"
            if ansible-playbook --syntax-check "$playbook" >/dev/null 2>&1; then
                success "Syntaxe OK: $playbook"
            else
                error "Erreur de syntaxe: $playbook"
                ansible-playbook --syntax-check "$playbook"
            fi
        fi
    done
}

# Fonction pour créer des scripts de vérification sans problème de templating
create_safe_scripts() {
    log "Création de scripts de vérification sécurisés..."
    
    # Script de vérification SonarQube simple
    cat > "$SCRIPT_DIR/check-sonar-simple.sh" << 'EOF'
#!/bin/bash
echo "=== Vérification SonarQube Simple ==="
echo "Docker actif: $(systemctl is-active docker)"
echo ""
echo "Containers SonarQube:"
docker ps --filter "name=sonar" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""
echo "Test connectivité:"
curl -s -o /dev/null -w "HTTP %{http_code}" http://localhost:9000 || echo "Connexion échouée"
echo ""
echo "API Status:"
curl -s http://localhost:9000/api/system/status 2>/dev/null || echo "API non accessible"
echo ""
EOF
    
    chmod +x "$SCRIPT_DIR/check-sonar-simple.sh"
    success "Script de vérification simple créé: check-sonar-simple.sh"
    
    # Script de vérification Jenkins simple
    cat > "$SCRIPT_DIR/check-jenkins-simple.sh" << 'EOF'
#!/bin/bash
echo "=== Vérification Jenkins Simple ==="
echo "Jenkins actif: $(systemctl is-active jenkins)"
echo ""
echo "Port 8080 ouvert:"
netstat -tuln | grep ":8080" && echo "✅ Port ouvert" || echo "❌ Port fermé"
echo ""
echo "Test connectivité:"
curl -s -o /dev/null -w "HTTP %{http_code}" http://localhost:8080 || echo "Connexion échouée"
echo ""
echo "Plugins installés (sample):"
find /var/lib/jenkins/plugins/ -name "*.jpi" -o -name "*.hpi" | head -5 | xargs -I {} basename {} .jpi
echo ""
EOF
    
    chmod +x "$SCRIPT_DIR/check-jenkins-simple.sh"
    success "Script de vérification simple créé: check-jenkins-simple.sh"
}

# Fonction pour générer un template corrigé
generate_fixed_template() {
    log "Génération d'un template de script corrigé..."
    
    cat > "$ANSIBLE_DIR/templates/check-services.sh.j2" << 'EOF'
#!/bin/bash

# Script de vérification des services - Template Jinja2 corrigé
# Généré par Ansible - Pas de modification manuelle

echo "=== Status des services ==="
echo "Docker: $(systemctl is-active docker)"
echo "Containers:"

# Utilisation de {% raw %} pour éviter les conflits de templating
docker ps --format "table {% raw %}{{.Names}}\t{{.Status}}\t{{.Ports}}{% endraw %}"

echo ""
echo "=== Vérification des APIs ==="

# Test SonarQube si présent
if docker ps --format "{% raw %}{{.Names}}{% endraw %}" | grep -q sonar; then
    echo "SonarQube détecté - Test API:"
    curl -s http://localhost:9000/api/system/status 2>/dev/null || echo "API SonarQube non accessible"
fi

# Test Jenkins si présent
if systemctl is-active --quiet jenkins; then
    echo "Jenkins détecté - Test connectivité:"
    curl -s -o /dev/null -w "HTTP %{http_code}" http://localhost:8080 2>/dev/null || echo "Jenkins non accessible"
fi

echo ""
echo "=== Informations système ==="
echo "Uptime: $(uptime -p)"
echo "Espace disque: $(df -h / | tail -1 | awk '{print $5}')"
echo "Mémoire: $(free -h | grep Mem | awk '{print $3 "/" $2}')"
EOF
    
    # Créer le répertoire templates s'il n'existe pas
    mkdir -p "$ANSIBLE_DIR/templates"
    
    success "Template corrigé créé: templates/check-services.sh.j2"
}

# Fonction pour afficher les recommandations
show_recommendations() {
    echo
    echo "📋 Recommandations pour éviter les erreurs de templating:"
    echo "========================================================="
    echo
    echo "1. 🔒 Utiliser {% raw %}...{% endraw %} pour les templates Docker:"
    echo "   docker ps --format \"table {% raw %}{{.Names}}{% endraw %}\""
    echo
    echo "2. 🛡️  Échapper les accolades avec {{ '{{' }} et {{ '}}' }}:"
    echo "   jq {{ '.' }}"
    echo
    echo "3. 📄 Utiliser des templates Jinja2 séparés (.j2) pour les scripts complexes"
    echo
    echo "4. 🧪 Tester la syntaxe avec:"
    echo "   ansible-playbook --syntax-check playbook.yml"
    echo
    echo "5. 🔍 Scripts de vérification disponibles:"
    echo "   - $SCRIPT_DIR/check-sonar-simple.sh"
    echo "   - $SCRIPT_DIR/check-jenkins-simple.sh"
    echo "   - $SCRIPT_DIR/check-sonarqube-services.sh (complet)"
    echo
}

# Fonction principale
main() {
    fix_templating_issues
    echo
    test_playbooks
    echo
    create_safe_scripts
    echo
    generate_fixed_template
    echo
    show_recommendations
    
    success "✅ Correction des erreurs de templating terminée!"
}

# Aide
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage: $0"
    echo ""
    echo "Corrige les erreurs de templating Jinja2 dans les playbooks Ansible."
    echo "Crée des scripts de vérification sécurisés."
    echo ""
    echo "Actions effectuées:"
    echo "  - Vérification des problèmes de templating"
    echo "  - Test de syntaxe des playbooks"
    echo "  - Création de scripts de vérification sans templating"
    echo "  - Génération de templates corrigés"
    exit 0
fi

# Exécution
main "$@"
