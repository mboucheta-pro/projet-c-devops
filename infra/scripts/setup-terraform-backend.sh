#!/bin/bash
# Script pour configurer le backend S3 de Terraform

# Configurer la région
export AWS_REGION=${1:-ca-central-1}
BUCKET_NAME="projet-c-terraform-state"
DYNAMODB_TABLE="projet-c-terraform-locks"

echo "Configuration du backend Terraform dans la région $AWS_REGION..."

# Créer le bucket S3
aws s3api create-bucket \
  --bucket $BUCKET_NAME \
  --region $AWS_REGION \
  --create-bucket-configuration LocationConstraint=$AWS_REGION

# Activer le versionnement sur le bucket
aws s3api put-bucket-versioning \
  --bucket $BUCKET_NAME \
  --versioning-configuration Status=Enabled

# Activer le chiffrement par défaut
aws s3api put-bucket-encryption \
  --bucket $BUCKET_NAME \
  --server-side-encryption-configuration '{
    "Rules": [
      {
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        }
      }
    ]
  }'

# Bloquer l'accès public
aws s3api put-public-access-block \
  --bucket $BUCKET_NAME \
  --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# Créer la table DynamoDB pour les verrous
aws dynamodb create-table \
  --region $AWS_REGION \
  --table-name $DYNAMODB_TABLE \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST

echo "Backend Terraform configuré avec succès!"
echo "Bucket S3: $BUCKET_NAME"
echo "Table DynamoDB: $DYNAMODB_TABLE"
echo "Région: $AWS_REGION"