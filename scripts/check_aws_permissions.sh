#!/bin/bash

# Script pour vérifier les permissions AWS nécessaires pour l'exécution du pipeline
# Ce script teste les différentes actions AWS utilisées par le pipeline et
# rapporte les problèmes de permissions éventuels

# Couleurs pour les messages
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Vérification des permissions AWS pour le pipeline...${NC}"

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

# Variables pour les ressources
REGION="ca-central-1"
BUCKET_NAME="projet-c-mohamed"
DYNAMODB_TABLE="terraform-locks"
PROJECT="projet-c"

# Fonction pour tester une permission
test_permission() {
    local service=$1
    local action=$2
    local resource=$3
    local description=$4
    
    echo -e "${YELLOW}Test: $description${NC}"
    
    # Exécuter la commande AWS
    if eval "$action" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ OK: $description${NC}"
        return 0
    else
        echo -e "${RED}❌ ÉCHEC: $description${NC}"
        return 1
    fi
}

# Vérifier le backend Terraform
test_permission "S3" "aws s3api head-bucket --bucket $BUCKET_NAME" "" "Accès au bucket S3 $BUCKET_NAME (backend Terraform)"
test_permission "DynamoDB" "aws dynamodb describe-table --table-name $DYNAMODB_TABLE --region $REGION" "" "Accès à la table DynamoDB $DYNAMODB_TABLE (verrouillage Terraform)"

# Vérifier les permissions EKS
test_permission "EKS" "aws eks list-clusters --region $REGION" "" "Lister les clusters EKS"

# Vérifier les permissions CloudWatch Logs
test_permission "CloudWatch Logs" "aws logs describe-log-groups --region $REGION" "" "Lister les groupes de logs CloudWatch"
test_permission "CloudWatch Logs" "aws logs list-tags-log-group --log-group-name test-log-group --region $REGION || true" "" "Lister les tags d'un groupe de logs CloudWatch"

# Vérifier les permissions IAM
test_permission "IAM" "aws iam list-roles --max-items 5" "" "Lister les rôles IAM"
test_permission "IAM" "aws iam list-policies --scope Local --max-items 5" "" "Lister les politiques IAM"

# Vérifier les permissions Secrets Manager
test_permission "Secrets Manager" "aws secretsmanager list-secrets --max-results 10 --region $REGION" "" "Lister les secrets dans Secrets Manager"

# Vérifier les permissions RDS
test_permission "RDS" "aws rds describe-db-instances --region $REGION" "" "Lister les instances RDS"

echo -e "\n${YELLOW}Résumé des tests de permissions AWS${NC}"
echo -e "${YELLOW}===================================${NC}"
echo -e "Ces tests ne sont pas exhaustifs mais donnent une indication sur les permissions"
echo -e "disponibles pour l'utilisateur AWS actuel."
echo -e "\nSi certains tests ont échoué, vous devrez peut-être mettre à jour les permissions IAM"
echo -e "en exécutant le script update_iam_permissions.sh ou en appliquant les modifications"
echo -e "Terraform dans le projet devops."
