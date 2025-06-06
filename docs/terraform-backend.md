# Backend S3 pour Terraform

Ce document explique comment fonctionne le backend S3 pour Terraform dans le projet.

## Qu'est-ce qu'un backend S3 ?

Le backend S3 permet de stocker l'état de Terraform dans un bucket S3 et d'utiliser DynamoDB pour le verrouillage d'état. Cela offre plusieurs avantages :

- **État partagé** : Plusieurs personnes peuvent travailler sur la même infrastructure
- **Verrouillage d'état** : Empêche les modifications simultanées qui pourraient corrompre l'état
- **Versionnement** : Historique complet des modifications de l'état
- **Chiffrement** : Protection des données sensibles dans l'état

## Configuration automatique

Le backend S3 est automatiquement configuré au début du pipeline CI/CD. Voici comment cela fonctionne :

1. Le job `setup-backend` vérifie si le bucket S3 et la table DynamoDB existent déjà
2. S'ils n'existent pas, ils sont créés avec les configurations appropriées :
   - Versionnement activé pour le bucket S3
   - Chiffrement côté serveur avec AES-256
   - Blocage de l'accès public
   - Table DynamoDB configurée pour le verrouillage d'état

## Configuration du backend

Le backend est configuré dans le fichier `infra/terraform/backend.tf` :

```hcl
terraform {
  backend "s3" {
    bucket         = "projet-c-terraform-state"
    key            = "terraform.tfstate"
    region         = "ca-central-1"
    encrypt        = true
    dynamodb_table = "projet-c-terraform-locks"
  }
}
```

## Variables d'environnement

Les noms du bucket S3 et de la table DynamoDB sont définis comme variables d'environnement dans le workflow CI/CD :

```yaml
env:
  TF_BACKEND_BUCKET: projet-c-terraform-state
  TF_BACKEND_DYNAMODB: projet-c-terraform-locks
```

## Sécurité

Le backend S3 est configuré avec les mesures de sécurité suivantes :

- **Chiffrement** : Chiffrement côté serveur avec AES-256
- **Accès privé** : Blocage de tout accès public au bucket
- **Versionnement** : Conservation de l'historique complet des états
- **Verrouillage** : Prévention des modifications concurrentes

## Utilisation locale

Si vous souhaitez utiliser le même backend S3 en local, assurez-vous que :

1. Vous avez configuré vos credentials AWS localement
2. Le bucket S3 et la table DynamoDB existent déjà (créés par le pipeline CI/CD)
3. Vous utilisez la même configuration dans votre fichier backend.tf

Ensuite, initialisez Terraform :

```bash
cd infra/terraform
terraform init
```

## Résolution des problèmes

Si vous rencontrez des erreurs liées au backend S3 :

1. Vérifiez que le bucket S3 et la table DynamoDB existent
2. Assurez-vous que vos credentials AWS ont les permissions nécessaires
3. Vérifiez que la région AWS est correctement configurée