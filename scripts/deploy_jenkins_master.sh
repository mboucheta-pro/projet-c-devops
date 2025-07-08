#!/bin/bash

# Récupérer les credentials Jenkins et la clé SSH depuis AWS Secrets Manager
export JENKINS_ADMIN_PASSWORD=$(aws secretsmanager get-secret-value --secret-id projet-c-devops-jenkins-credentials --query SecretString --output text --region ca-central-1 | jq -r '.admin_password')
export JENKINS_ADMIN_USERNAME=$(aws secretsmanager get-secret-value --secret-id projet-c-devops-jenkins-credentials --query SecretString --output text --region ca-central-1 | jq -r '.admin_username')
SSH_PRIVATE_KEY=$(aws secretsmanager get-secret-value --secret-id SSH_PRIVATE_KEY --query SecretString --output text --region ca-central-1)

# Initaliser l'agent ssh
cd $GITHUB_WORKSPACE/infra/ansible
eval "$(ssh-agent -s)"
ssh-add <(echo "$SSH_PRIVATE_KEY")

# Créer le fichier d'inventaire avec les IPs réelles
cat > inventory_jenkins.yml << EOF
all:
  vars:
    ansible_user: ubuntu
    ansible_ssh_common_args: '-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'

  children:
    jenkins:
      hosts:
        jenkins-master:
          ansible_host: "${JENKINS_IP}"
EOF

# Installer les rôles Ansible
ansible-galaxy install geerlingguy.java --force
ansible-galaxy install geerlingguy.jenkins --force

# Déployer Jenkins master
ansible-playbook -i inventory_jenkins.yml jenkins-playbook.yml -v

# Nettoyer les fichiers temporaires
rm -f inventory_jenkins.yml

echo "Déploiement Jenkins terminé"