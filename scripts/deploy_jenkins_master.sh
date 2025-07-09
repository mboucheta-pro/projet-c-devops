#!/bin/bash
set -euo pipefail

# Script simplifié de déploiement Jenkins Master
echo "🚀 Déploiement Jenkins Master simplifié..."

# Récupérer les credentials depuis AWS Secrets Manager
export JENKINS_ADMIN_PASSWORD=$(aws secretsmanager get-secret-value --secret-id projet-c-devops-jenkins-credentials --query SecretString --output text --region ca-central-1 | jq -r '.admin_password')
export JENKINS_ADMIN_USERNAME=$(aws secretsmanager get-secret-value --secret-id projet-c-devops-jenkins-credentials --query SecretString --output text --region ca-central-1 | jq -r '.admin_username')
SSH_PRIVATE_KEY=$(aws secretsmanager get-secret-value --secret-id SSH_PRIVATE_KEY --query SecretString --output text --region ca-central-1)

# Récupérer l'IP SonarQube
export SONARQUBE_IP=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=sonarqube" "Name=instance-state-name,Values=running" \
  --query "Reservations[].Instances[].PublicIpAddress" \
  --output text \
  --region ca-central-1)

# Créer la clé SSH temporaire
SSH_KEY_FILE=$(mktemp)
echo "$SSH_PRIVATE_KEY" > "$SSH_KEY_FILE"
chmod 600 "$SSH_KEY_FILE"

cd $GITHUB_WORKSPACE/infra/ansible

# Créer l'inventaire simple
cat > inventory.ini << EOF
[jenkins]
jenkins-master ansible_host=${JENKINS_IP} ansible_user=ubuntu ansible_ssh_private_key_file=${SSH_KEY_FILE}
EOF

# Déployer Jenkins master
ansible-playbook -i inventory.ini jenkins-master-playbook.yml

# Nettoyer
rm -f inventory.ini "$SSH_KEY_FILE"

echo "✅ Déploiement Jenkins terminé"