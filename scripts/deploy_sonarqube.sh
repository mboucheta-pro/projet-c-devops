#!/bin/bash

# Récupérer les outputs Terraform
export SONARQUBE_ADMIN_PASSWORD=$(aws secretsmanager get-secret-value --secret-id projet-c-devops-sonarqube-credentials --query SecretString --output text --region ca-central-1 | jq -r '.admin_password')
export SONARQUBE_ADMIN_USERNAME=$(aws secretsmanager get-secret-value --secret-id projet-c-devops-sonarqube-credentials --query SecretString --output text --region ca-central-1 | jq -r '.admin_username')
SSH_PRIVATE_KEY=$(aws secretsmanager get-secret-value --secret-id SSH_PRIVATE_KEY --query SecretString --output text --region ca-central-1)

# Récupérer l'adresse IP de Jenkins
export JENKINS_IP=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=jenkins" "Name=instance-state-name,Values=running" \
  --query "Reservations[].Instances[].PublicIpAddress" \
  --output text \
  --region ca-central-1)

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
rm -f inventory_sonarqube.yml

echo "Déploiement Sonarqube terminé"
echo
echo "===================================================="
echo "IMPORTANT: Configuration manuelle requise"
echo "===================================================="
echo "SonarQube est accessible à l'adresse: http://$SONARQUBE_IP:9000"
echo "Identifiants par défaut: admin/admin"
echo
echo "Pour configurer l'intégration avec Jenkins:"
echo "1. Connectez-vous à SonarQube et créez un token dans votre profil utilisateur"
echo "2. Stockez ce token dans AWS Secrets Manager en créant un secret nommé SONARQUBE_TOKEN"
echo "3. Configurez le serveur SonarQube dans Jenkins (Manage Jenkins > Configure System)"
echo "4. Configurez un webhook dans SonarQube pointant vers Jenkins: http://$JENKINS_IP:8080/sonarqube-webhook/"
echo "===================================================="