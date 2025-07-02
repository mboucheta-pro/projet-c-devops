# Recommandations pour corriger l'infrastructure IaC

## 1. SUPPRIMER le fichier vpc.tf
Le module VPC dans main.tf est suffisant. Supprimer complètement vpc.tf.

## 2. CORRIGER la configuration RDS
```hcl
resource "aws_secretsmanager_secret" "db_credentials" {
  name = "${var.project}/rds/credentials"
  description = "Credentials pour la base de données RDS"
  kms_key_id = aws_kms_key.secrets.arn  # Ajouter une clé KMS
  tags = local.tags
}

resource "aws_kms_key" "secrets" {
  description = "KMS key for secrets encryption"
  tags = local.tags
}
```

## 3. CRÉER des actions composites GitHub
```yaml
# .github/actions/setup-aws/action.yml
name: 'Setup AWS Credentials'
description: 'Setup AWS credentials from base64 secret'
runs:
  using: 'composite'
  steps:
    - name: Decode AWS credentials
      shell: bash
      run: |
        echo "${{ secrets.AWS_CREDENTIALS_BASE64 }}" | base64 -d > aws-credentials.json
        echo "AWS_ACCESS_KEY_ID=$(jq -r .aws_access_key_id aws-credentials.json)" >> $GITHUB_ENV
        echo "AWS_SECRET_ACCESS_KEY=$(jq -r .aws_secret_access_key aws-credentials.json)" >> $GITHUB_ENV
        rm aws-credentials.json
```

## 4. SIMPLIFIER le workflow
```yaml
# Utiliser l'action composite
- uses: ./.github/actions/setup-aws

# Créer une fonction pour la logique conditionnelle
- name: Set instance state
  run: |
    if [[ "${{ github.event.inputs.action }}" =~ ^(deploy|sortie-de-veille)$ ]]; then
      echo "INSTANCES_RUNNING=true" >> $GITHUB_ENV
    else
      echo "INSTANCES_RUNNING=false" >> $GITHUB_ENV
    fi
```

## 5. OPTIMISER la structure Terraform
```
infra/
├── terraform/
│   ├── modules/
│   │   ├── vpc/
│   │   ├── security/
│   │   └── compute/
│   ├── environments/
│   │   ├── dev/
│   │   └── prod/
│   └── shared/
```

## 6. CORRIGER les security groups
Déplacer toutes les règles de sécurité dans security.tf et supprimer les doublons.

## 7. AJOUTER la validation
```hcl
# versions.tf
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```