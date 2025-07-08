#!/bin/bash

# Script pour appliquer les modifications IAM au rôle Jenkins
# Ce script applique les modifications IAM à l'environnement AWS
# pour que le rôle Jenkins ait toutes les permissions nécessaires

# Couleurs pour les messages
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Mise à jour des permissions IAM pour le rôle Jenkins...${NC}"

# Vérification des credentials AWS
if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    if [ -f "$HOME/.aws/credentials.env" ]; then
        echo -e "${YELLOW}Chargement des credentials depuis ~/.aws/credentials.env${NC}"
        source "$HOME/.aws/credentials.env"
    else
        echo -e "${RED}❌ Les credentials AWS ne sont pas configurés. Exécutez:${NC}"
        echo "export AWS_ACCESS_KEY_ID=votre_access_key"
        echo "export AWS_SECRET_ACCESS_KEY=votre_secret_key"
        exit 1
    fi
fi

# Vérifier que AWS CLI est disponible
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI n'est pas installé. Veuillez l'installer:${NC}"
    echo "pip install awscli"
    exit 1
fi

# Vérifier que Terraform est disponible
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}❌ Terraform n'est pas installé. Veuillez l'installer.${NC}"
    exit 1
fi

# Se déplacer dans le répertoire Terraform du projet DevOps
cd "$(dirname "$0")/../infra/terraform" || {
    echo -e "${RED}❌ Impossible d'accéder au répertoire Terraform${NC}"
    exit 1
}

echo -e "${YELLOW}Initialisation de Terraform...${NC}"
terraform init

echo -e "${YELLOW}Validation de la configuration Terraform...${NC}"
terraform validate

echo -e "${YELLOW}Exécution de Terraform plan...${NC}"
terraform plan -target=aws_iam_role_policy.cicd_instances -out=tfplan

echo -e "${YELLOW}Application des modifications IAM...${NC}"
terraform apply -target=aws_iam_role_policy.cicd_instances tfplan

echo -e "${GREEN}✅ Les permissions IAM ont été mises à jour avec succès!${NC}"
echo -e "${YELLOW}Vous pouvez maintenant relancer le pipeline Jenkins pour valider que les permissions sont correctes.${NC}"
