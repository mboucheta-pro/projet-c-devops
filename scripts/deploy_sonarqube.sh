#!/bin/bash
set -euo pipefail

# Script simplifié de déploiement SonarQube
echo "🚀 Déploiement SonarQube simplifié..."

# Récupérer les credentials depuis AWS Secrets Manager
export SONARQUBE_ADMIN_PASSWORD=$(aws secretsmanager get-secret-value --secret-id projet-c-devops-sonarqube-credentials --query SecretString --output text --region ca-central-1 | jq -r '.admin_password')
export SONARQUBE_ADMIN_USERNAME=$(aws secretsmanager get-secret-value --secret-id projet-c-devops-sonarqube-credentials --query SecretString --output text --region ca-central-1 | jq -r '.admin_username')
SSH_PRIVATE_KEY=$(aws secretsmanager get-secret-value --secret-id SSH_PRIVATE_KEY --query SecretString --output text --region ca-central-1)

# Créer la clé SSH temporaire
SSH_KEY_FILE=$(mktemp)
echo "$SSH_PRIVATE_KEY" > "$SSH_KEY_FILE"
chmod 600 "$SSH_KEY_FILE"

cd $GITHUB_WORKSPACE/infra/ansible

# Créer l'inventaire simple
cat > inventory.ini << EOF
[sonarqube]
sonar-server ansible_host=${SONARQUBE_IP} ansible_user=ubuntu ansible_ssh_private_key_file=${SSH_KEY_FILE}
EOF

# Déployer SonarQube
ansible-playbook -i inventory.ini sonarqube-playbook.yml -v

# Nettoyer
rm -f inventory.ini "$SSH_KEY_FILE"

echo "✅ Déploiement SonarQube terminé"
echo "📍 SonarQube: http://$SONARQUBE_IP:9000 (admin/admin)"