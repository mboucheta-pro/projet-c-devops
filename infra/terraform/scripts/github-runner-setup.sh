#!/bin/bash
set -e

# Variables
GITHUB_TOKEN="${github_token}"
GITHUB_REPO="${github_repo}"
RUNNER_NAME="${runner_name}"
RUNNER_USER="runner"

# Mise à jour du système
apt-get update
apt-get upgrade -y

# Installation des dépendances
apt-get install -y curl wget jq git docker.io

# Démarrage de Docker
systemctl start docker
systemctl enable docker

# Création de l'utilisateur runner
useradd -m -s /bin/bash $RUNNER_USER
usermod -aG docker $RUNNER_USER

# Téléchargement du runner GitHub
cd /home/$RUNNER_USER
RUNNER_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | jq -r '.tag_name' | sed 's/v//')
wget -O actions-runner-linux-x64.tar.gz https://github.com/actions/runner/releases/download/v$RUNNER_VERSION/actions-runner-linux-x64-$RUNNER_VERSION.tar.gz
tar xzf actions-runner-linux-x64.tar.gz
rm actions-runner-linux-x64.tar.gz

# Changement de propriétaire
chown -R $RUNNER_USER:$RUNNER_USER /home/$RUNNER_USER

# Obtention du token d'enregistrement
REGISTRATION_TOKEN=$(curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/$GITHUB_REPO/actions/runners/registration-token | jq -r '.token')

# Configuration du runner
sudo -u $RUNNER_USER ./config.sh \
  --url https://github.com/$GITHUB_REPO \
  --token $REGISTRATION_TOKEN \
  --name $RUNNER_NAME \
  --work _work \
  --labels self-hosted,linux,x64,aws \
  --unattended

# Installation du service
./svc.sh install $RUNNER_USER
./svc.sh start

# Installation d'outils supplémentaires
apt-get install -y nodejs npm python3 python3-pip
npm install -g yarn

# Configuration des logs
mkdir -p /var/log/github-runner
chown $RUNNER_USER:$RUNNER_USER /var/log/github-runner

echo "GitHub Runner installé et configuré avec succès"