# Infrastructure Terraform pour Projet-C

Cette configuration Terraform déploie l'infrastructure nécessaire pour le projet-C sur AWS.

## Composants déployés

- VPC avec subnets publics et privés
- Runner GitHub (EC2 t3a.small)
- Serveur SonarQube (EC2 t3a.medium)
- Serveur de monitoring pour Prometheus et Grafana (EC2 t3a.small)
- Base de données MySQL (RDS db.t3.small)
- Cluster Kubernetes EKS avec des nœuds Spot pour optimiser les coûts

## Optimisations de coûts

- Utilisation d'instances t3a (AMD) moins coûteuses que les t3 (Intel)
- Single NAT Gateway pour réduire les coûts de NAT
- Instances Spot pour les nœuds EKS
- Dimensionnement minimal des ressources
- Multi-AZ désactivé pour la base de données en environnement de développement

## Prérequis

- AWS CLI configuré
- Terraform v1.0.0+

## Utilisation

```bash
# Initialiser Terraform
terraform init

# Vérifier le plan
terraform plan

# Appliquer la configuration
terraform apply

# Détruire l'infrastructure
terraform destroy
```

## Variables

Les variables principales sont définies dans `variables.tf`. Pour personnaliser le déploiement, créez un fichier `terraform.tfvars` avec vos valeurs.

## Sécurité

**Important :** Avant de déployer en production :

1. Remplacer les mots de passe par défaut
2. Utiliser AWS Secrets Manager pour les informations sensibles
3. Restreindre les règles de sécurité pour SSH (actuellement ouvert à 0.0.0.0/0)
4. Activer le chiffrement pour les volumes et la base de données