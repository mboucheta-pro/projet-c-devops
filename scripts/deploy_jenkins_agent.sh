#!/bin/bash
set -euo pipefail

# Script simplifié de déploiement Jenkins Agent
echo "🚀 Déploiement Jenkins Agent simplifié..."

# Récupérer les credentials depuis AWS Secrets Manager
SSH_PRIVATE_KEY=$(aws secretsmanager get-secret-value --secret-id SSH_PRIVATE_KEY --query SecretString --output text --region ca-central-1)

# Créer la clé SSH temporaire
SSH_KEY_FILE=$(mktemp)
echo "$SSH_PRIVATE_KEY" > "$SSH_KEY_FILE"
chmod 600 "$SSH_KEY_FILE"

cd $GITHUB_WORKSPACE/infra/ansible

# Créer l'inventaire simple
cat > inventory.ini << EOF
[jenkins_agents]
jenkins-agent ansible_host=${JENKINS_AGENT_IP} ansible_user=ubuntu ansible_ssh_private_key_file=${SSH_KEY_FILE} jenkins_master_ip=${JENKINS_IP}
EOF

# Déployer avec le playbook simplifié
ansible-playbook -i inventory.ini jenkins-agent-simple.yml

# Nettoyer
rm -f inventory.ini "$SSH_KEY_FILE"

echo "✅ Déploiement terminé"