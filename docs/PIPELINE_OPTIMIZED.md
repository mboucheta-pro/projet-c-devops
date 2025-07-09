# Pipeline GitHub Actions Optimisé - Documentation

## Vue d'ensemble

Le pipeline GitHub Actions a été optimisé avec une architecture modulaire utilisant des actions réutilisables pour améliorer la maintenabilité et réduire la duplication de code.

## Structure des Actions Réutilisables

### 1. `setup-terraform` (existante)
- **Rôle** : Configuration des credentials AWS et installation de Terraform
- **Utilisation** : Utilisée par tous les jobs

### 2. `setup-aws-backend` (nouvelle)
- **Rôle** : Création et configuration du backend S3 + DynamoDB
- **Paramètres** :
  - `bucket_name` : Nom du bucket S3 (défaut: `projet-c-mohamed`)
  - `table_name` : Nom de la table DynamoDB (défaut: `terraform-locks`)
  - `region` : Région AWS (défaut: `ca-central-1`)

### 3. `setup-terraform-infrastructure` (nouvelle)
- **Rôle** : Gestion des opérations Terraform (plan, apply, destroy)
- **Paramètres** :
  - `action` : Action à effectuer (`plan`, `apply`, `destroy`)
  - `terraform_path` : Chemin vers les fichiers Terraform (défaut: `infra/terraform`)
- **Outputs** :
  - `terraform_output` : Sortie JSON des outputs Terraform

### 4. `get-infrastructure-ips` (nouvelle)
- **Rôle** : Récupération des IPs depuis les outputs Terraform
- **Outputs** :
  - `jenkins_ip` : IP du serveur Jenkins Master
  - `jenkins_agent_ip` : IP du serveur Jenkins Agent
  - `sonarqube_ip` : IP du serveur SonarQube

### 5. `configure-component` (nouvelle)
- **Rôle** : Configuration d'un composant spécifique
- **Paramètres** :
  - `component` : Composant à configurer (`sonarqube`, `jenkins-master`, `jenkins-agent`)
  - `component_ip` : IP du composant
  - `should_configure` : Indique si le composant doit être configuré

## Workflows Disponibles

### 1. `create_backend`
- **Objectif** : Créer uniquement le backend S3 + DynamoDB
- **Utilisation** : Première fois ou réinitialisation du backend
- **Actions utilisées** : `setup-terraform`, `setup-aws-backend`

### 2. `create_infra`
- **Objectif** : Créer/mettre à jour l'infrastructure complète
- **Options** :
  - `configure_all` : Configure automatiquement tous les composants après création
- **Actions utilisées** : `setup-terraform`, `setup-terraform-infrastructure`, `get-infrastructure-ips`, `configure-component`

### 3. `configure_components`
- **Objectif** : Configuration sélective des composants
- **Options** :
  - `configure_sonarqube` : Configure SonarQube
  - `configure_jenkins_master` : Configure Jenkins Master
  - `configure_jenkins_agent` : Configure Jenkins Agent
- **Actions utilisées** : `setup-terraform`, `get-infrastructure-ips`, `configure-component`

### 4. `destroy`
- **Objectif** : Détruire l'infrastructure
- **Sécurité** : Requiert la confirmation explicite (`confirm: true`)
- **Actions utilisées** : `setup-terraform`, `setup-terraform-infrastructure`

## Avantages de l'Optimisation

### 1. **Réduction de la Duplication**
- Code de récupération des IPs factorisé
- Logique de configuration des composants centralisée
- Opérations Terraform standardisées

### 2. **Maintenabilité Améliorée**
- Modifications centralisées dans les actions
- Code plus lisible et structuré
- Réutilisabilité entre différents workflows

### 3. **Gestion d'Erreurs Cohérente**
- Validation des paramètres centralisée
- Messages d'erreur standardisés
- Rollback et récupération simplifiés

### 4. **Flexibilité**
- Paramètres configurables pour chaque action
- Possibilité d'utiliser les actions dans d'autres workflows
- Extensibilité pour de nouveaux composants

## Utilisation Recommandée

### Première Installation
1. Exécuter `create_backend` pour préparer le backend Terraform
2. Exécuter `create_infra` avec `configure_all: true` pour déployer et configurer tout

### Maintenance
- Utiliser `configure_components` pour reconfigurer des composants spécifiques
- Utiliser `create_infra` pour les mises à jour d'infrastructure

### Développement
- Utiliser `create_infra` sans `configure_all` pour des tests rapides
- Utiliser `configure_components` pour tester des configurations spécifiques

## Structure des Fichiers

```
.github/
├── actions/
│   ├── setup-terraform/
│   │   └── action.yml
│   ├── setup-aws-backend/
│   │   └── action.yml
│   ├── setup-terraform-infrastructure/
│   │   └── action.yml
│   ├── get-infrastructure-ips/
│   │   └── action.yml
│   └── configure-component/
│       └── action.yml
└── workflows/
    └── infrastructure.yml
```

## Variables d'Environnement Requises

### Secrets GitHub
- `AWS_CREDENTIALS_BASE64` : Credentials AWS encodées en base64

### AWS Secrets Manager
- `projet-c-devops-jenkins-credentials` : Credentials Jenkins
- `projet-c-devops-sonarqube-credentials` : Credentials SonarQube
- `SSH_PRIVATE_KEY` : Clé SSH privée pour les serveurs

## Logs et Monitoring

Chaque action produit des logs structurés avec des émojis pour faciliter le suivi :
- 🚀 Démarrage d'une action
- ✅ Succès d'une opération
- 🔧 Configuration en cours
- 📋 Résumé des actions
- ❌ Erreur rencontrée
- 🔄 Opération en cours

## Troubleshooting

### Problème : IP non récupérée
- Vérifier que l'infrastructure est déployée
- Contrôler les outputs Terraform
- Vérifier les permissions AWS

### Problème : Configuration échouée
- Vérifier les secrets AWS Secrets Manager
- Contrôler la connectivité SSH
- Vérifier les playbooks Ansible

### Problème : Terraform state lock
- Vérifier la table DynamoDB
- Libérer le lock manuellement si nécessaire
- Recréer le backend si corrompu
