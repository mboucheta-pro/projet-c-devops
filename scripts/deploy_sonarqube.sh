#!/bin/bash

# Récupérer les outputs Terraform
export SONARQUBE_ADMIN_PASSWORD=$(aws secretsmanager get-secret-value --secret-id projet-c-devops-sonarqube-credentials --query SecretString --output text --region ca-central-1 | jq -r '.admin_password')
export SONARQUBE_ADMIN_USERNAME=$(aws secretsmanager get-secret-value --secret-id projet-c-devops-sonarqube-credentials --query SecretString --output text --region ca-central-1 | jq -r '.admin_username')
SSH_PRIVATE_KEY=$(aws secretsmanager get-secret-value --secret-id SSH_PRIVATE_KEY --query SecretString --output text --region ca-central-1)

# Initaliser l'agent ssh
cd $GITHUB_WORKSPACE/infra/ansible
eval "$(ssh-agent -s)"
ssh-add <(echo "$SSH_PRIVATE_KEY")

# Créer le fichier d'inventaire avec les IPs réelles
cat > inventory_sonarqube.yml << EOF
all:
  vars:
    ansible_user: ubuntu
    ansible_ssh_common_args: '-o StrictHostKeyChecking=no'

  children:
    sonarqube:
      hosts:
        sonar-server:
          ansible_host: "$SONARQUBE_IP"
EOF
cat inventory_sonarqube.yml 
ansible-playbook -i inventory_sonarqube.yml sonarqube-playbook.yml -v

# Nettoyer les fichiers temporaires
rm -f inventory_jenkins.yml

echo "Déploiement Sonarqube terminé"