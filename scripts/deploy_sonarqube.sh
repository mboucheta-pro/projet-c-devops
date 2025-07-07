#!/bin/bash

# Récupérer les outputs Terraform
cd $GITHUB_WORKSPACE/infra/terraform
export SONAR_IP=$(terraform output -raw sonarqube_ip)

# Récupérer les credentials Jenkins et la clé SSH depuis AWS Secrets Manager
export SONARQUBE_PASSWORD=$(aws secretsmanager get-secret-value --secret-id projet-c-devops-sonarqube-credentials --query SecretString --output text --region ca-central-1 | jq -r '.admin_password')
export SSH_PRIVATE_KEY=$(aws secretsmanager get-secret-value --secret-id SSH_PRIVATE_KEY --query SecretString --output text --region ca-central-1)

# Créer le fichier de clé SSH temporaire
cd $GITHUB_WORKSPACE/infra/ansible
SSH_KEY_FILE=./projet-c-key.pem
echo "$SSH_PRIVATE_KEY" > $SSH_KEY_FILE
chmod 600 $SSH_KEY_FILE
cat $SSH_KEY_FILE

# Créer le fichier d'inventaire avec les IPs réelles
cat > inventory_sonar.yml << EOF
all:
vars:
    ansible_user: ubuntu
    ansible_ssh_private_key_file: "$GITHUB_WORKSPACE/projet-c.pem"
    ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
children:
    sonarqube:
    hosts:
        sonar-server:
        ansible_host: "$SONAR_IP"
EOF

ansible-playbook -i inventory_sonar.yml sonarqube-playbook.yml

# Nettoyer les fichiers temporaires
rm -f inventory_jenkins.yml
rm -f $SSH_KEY_FILE
echo "Déploiement Sonarqube terminé"