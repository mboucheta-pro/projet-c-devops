#!/bin/bash
set -euo pipefail

# Récupérer les credentials Jenkins et la clé SSH depuis AWS Secrets Manager
export JENKINS_ADMIN_PASSWORD=$(aws secretsmanager get-secret-value --secret-id projet-c-devops-jenkins-credentials --query SecretString --output text --region ca-central-1 | jq -r '.admin_password')
export JENKINS_ADMIN_USERNAME=$(aws secretsmanager get-secret-value --secret-id projet-c-devops-jenkins-credentials --query SecretString --output text --region ca-central-1 | jq -r '.admin_username')
SSH_PRIVATE_KEY=$(aws secretsmanager get-secret-value --secret-id SSH_PRIVATE_KEY --query SecretString --output text --region ca-central-1)

# Écrire la clé privée dans un fichier temporaire avec permissions sécurisées
SSH_KEY_FILE=$(mktemp)
echo "$SSH_PRIVATE_KEY" > "$SSH_KEY_FILE"
chmod 600 "$SSH_KEY_FILE"

# Initaliser l'agent ssh
cd $GITHUB_WORKSPACE/infra/ansible
eval "$(ssh-agent -s)"
ssh-add "$SSH_KEY_FILE"

# Créer le fichier d'inventaire avec les IPs réelles
cat > inventory_jenkins_agent.yml << EOF
all:
  vars:
    ansible_user: ubuntu
    ansible_ssh_private_key_file: "${SSH_KEY_FILE}"
    ansible_ssh_common_args: '-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
    jenkins_master_url: "http://${JENKINS_IP}:8080"

  children:
    jenkins_agents:
      hosts:
        jenkins-agent:
          ansible_host: "${JENKINS_AGENT_IP}"
EOF
cat inventory_jenkins_agent.yml
# Déployer l'agent Jenkins
ansible-playbook -i inventory_jenkins_agent.yml jenkins-agent-playbook.yml -vvvvv

# Nettoyer les fichiers temporaires
rm -f inventory_jenkins_agent.yml

echo "Déploiement de l'agent Jenkins terminé"