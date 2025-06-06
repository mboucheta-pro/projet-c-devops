# Automatisation complète du déploiement

Le Projet-C est entièrement automatisé via un pipeline CI/CD qui gère toutes les étapes, de la création de l'infrastructure jusqu'au déploiement de l'application.

## Vue d'ensemble

Le pipeline CI/CD est configuré pour exécuter automatiquement les étapes suivantes :

1. **Création de l'infrastructure** avec Terraform
2. **Configuration des serveurs** avec Ansible
3. **Tests et scans de sécurité** de l'application
4. **Construction et publication** des images Docker
5. **Déploiement** sur le cluster Kubernetes
6. **Génération d'un rapport** avec les informations d'accès

## Déclenchement du pipeline

Le pipeline peut être déclenché de trois façons :

1. **Automatiquement** lors d'un push sur les branches `main` ou `develop`
2. **Automatiquement** lors de la création d'une pull request vers ces branches
3. **Manuellement** via l'interface GitHub Actions avec le choix de l'environnement

## Gestion des secrets

Le pipeline utilise une approche sécurisée pour la gestion des secrets :

### Credentials AWS

Les credentials AWS sont stockés dans un secret GitHub nommé `AWS_CREDENTIALS_BASE64` qui contient un fichier JSON encodé en base64 :

```json
{
  "aws_access_key_id": "VOTRE_ACCESS_KEY",
  "aws_secret_access_key": "VOTRE_SECRET_KEY"
}
```

Pour créer ce secret :
```bash
# Créer le fichier JSON
echo '{"aws_access_key_id":"VOTRE_ACCESS_KEY","aws_secret_access_key":"VOTRE_SECRET_KEY"}' > aws-credentials.json

# Encoder en base64
base64 -i aws-credentials.json

# Copier la sortie et la coller dans le secret GitHub
```

### Secrets générés automatiquement

Les secrets suivants sont générés automatiquement pendant l'exécution du pipeline :

- **Clé SSH** : Générée au début du pipeline pour l'accès aux instances
- **Mot de passe de la base de données** : Généré aléatoirement
- **Token GitHub Runner** : Généré via l'API GitHub

Ces secrets sont sauvegardés en tant qu'artifacts du workflow et peuvent être téléchargés après l'exécution.

## Étapes détaillées du pipeline

### 1. Infrastructure (Terraform)

Cette étape :
- Décode les credentials AWS depuis le secret GitHub
- Génère une paire de clés SSH
- Génère un mot de passe pour la base de données
- Initialise Terraform
- Crée l'infrastructure
- Sauvegarde les outputs et les secrets générés

### 2. Configuration des serveurs (Ansible)

Cette étape :
- Récupère les outputs Terraform et les clés SSH
- Génère un token pour le GitHub Runner
- Crée un inventaire Ansible dynamique
- Configure les serveurs avec Ansible

### 3. Build et test de l'application

Cette étape :
- Installe les dépendances
- Exécute les tests unitaires
- Vérifie la qualité du code

### 4. Scan de sécurité

Cette étape :
- Analyse les vulnérabilités dans le code et les dépendances
- Bloque le pipeline en cas de vulnérabilités critiques

### 5. Construction et publication des images

Cette étape :
- Construit les images Docker pour le frontend et le backend
- Tague les images selon l'environnement
- Publie les images dans Amazon ECR

### 6. Déploiement

Cette étape :
- Initialise la base de données
- Configure kubectl pour accéder au cluster EKS
- Applique les configurations Kubernetes
- Déploie l'application dans le namespace correspondant à l'environnement

### 7. Génération du rapport

Cette étape :
- Crée un rapport de déploiement avec toutes les informations importantes
- Sauvegarde le rapport en tant qu'artifact

## Environnements

Le pipeline détecte automatiquement l'environnement cible en fonction de la branche :

| Branche | Environnement |
|---------|--------------|
| `main` | production |
| `develop` | staging |
| Autres branches | development |

## Récupération des informations de déploiement

Après l'exécution du pipeline, vous pouvez télécharger les artifacts suivants :

1. **terraform-outputs** : Contient les outputs Terraform (IPs, endpoints, etc.)
2. **credentials** : Contient la clé SSH privée et le mot de passe de la base de données
3. **credentials-updated** : Contient également le token GitHub Runner
4. **deployment-report** : Rapport complet du déploiement

Pour télécharger ces artifacts :
1. Accédez à l'exécution du workflow dans GitHub Actions
2. Cliquez sur l'onglet "Artifacts"
3. Téléchargez les artifacts souhaités