#!/bin/bash

# Récupérer les outputs Terraform
cd $GITHUB_WORKSPACE/infra/terraform
export JENKINS_IP=$(terraform output -raw jenkins_ip)

# Récupérer les credentials Jenkins et la clé SSH depuis AWS Secrets Manager
export JENKINS_ADMIN_PASSWORD=$(aws secretsmanager get-secret-value --secret-id projet-c-devops-jenkins-credentials --query SecretString --output text --region ca-central-1 | jq -r '.admin_password')
export JENKINS_ADMIN_USERNAME=$(aws secretsmanager get-secret-value --secret-id projet-c-devops-jenkins-credentials --query SecretString --output text --region ca-central-1 | jq -r '.admin_username')
SSH_PRIVATE_KEY=$(aws secretsmanager get-secret-value --secret-id SSH_PRIVATE_KEY --query SecretString --output text --region ca-central-1)

# Créer le fichier de clé SSH temporaire
cd $GITHUB_WORKSPACE/infra/ansible
eval "$(ssh-agent -s)"
ssh-add <(echo "$SSH_PRIVATE_KEY")

# Exporter les variables d'environnement pour Ansible
export JENKINS_MASTER_URL="http://${JENKINS_IP}:8080"

# Créer le fichier d'inventaire avec les IPs réelles
cat > inventory_jenkins.yml << EOF
all:
  vars:
    ansible_user: ubuntu
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

# Déployer Jenkins
cat inventory_jenkins.yml
ansible-playbook -i inventory_jenkins.yml jenkins-playbook.yml -vv

# Nettoyer les fichiers temporaires
rm -f inventory_jenkins.yml

echo "Déploiement Jenkins terminé"