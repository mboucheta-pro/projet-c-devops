#!/bin/bash

cd $GITHUB_WORKSPACE/infra/terraform

# Récupérer les outputs Terraform
JENKINS_IP=$(terraform output -raw jenkins_ip)

# Récupérer les credentials Jenkins et la clé SSH depuis AWS Secrets Manager
JENKINS_PASSWORD=$(aws secretsmanager get-secret-value --secret-id projet-c-devops-jenkins-credentials --query SecretString --output text --region ca-central-1 | jq -r '.admin_password')
SSH_PRIVATE_KEY=$(aws secretsmanager get-secret-value --secret-id SSH_PRIVATE_KEY --query SecretString --output text --region ca-central-1)

# Créer le fichier de clé SSH temporaire
cd $GITHUB_WORKSPACE/infra/ansible
SSH_KEY_FILE=./projet-c-key.pem
echo "$SSH_PRIVATE_KEY" > $SSH_KEY_FILE
chmod 600 $SSH_KEY_FILE

# Exporter les variables d'environnement pour Ansible
export JENKINS_ADMIN_PASSWORD="${JENKINS_PASSWORD}"
export JENKINS_MASTER_URL="http://${JENKINS_IP}:8080"

# Créer le fichier d'inventaire avec les IPs réelles
cat > inventory_jenkins.yml << EOF
all:
  vars:
    ansible_user: ubuntu
    ansible_ssh_private_key_file: "${SSH_KEY_FILE}"
    ansible_ssh_common_args: '-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'

  children:
    jenkins:
      hosts:
        jenkins-server:
          ansible_host: "${JENKINS_IP}"
EOF

# Installer les rôles Ansible
ansible-galaxy install geerlingguy.java --force
ansible-galaxy install geerlingguy.jenkins --force
ansible-galaxy collection install community.general --force

# Déployer Jenkins
ansible-playbook -i inventory_jenkins.yml jenkins-playbook.yml -v

# Nettoyer les fichiers temporaires
rm -f inventory_jenkins.yml
rm -f $SSH_KEY_FILE

echo "Déploiement Jenkins terminé"