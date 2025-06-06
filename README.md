# Projet C

## Objectif

Construire une pipeline de CI/CD permettant de déployer une application sur une infrastructure hébergée dans le Cloud.

## Documentation complète

La documentation complète du projet est disponible dans le répertoire [docs](./docs/README.md).

## Technologies utilisées

- **Cloud** : AWS
- **Infrastructure as Code** : Terraform, Ansible
- **Conteneurisation** : Docker, Kubernetes (EKS)
- **Langages** : Node.js (Express) pour le backend, HTML/CSS/JS pour le frontend
- **Base de données** : MySQL (RDS)
- **CI/CD** : GitHub Actions
- **Monitoring** : Prometheus, Grafana
- **Qualité** : SonarQube

## Architecture

![Architecture](https://via.placeholder.com/800x400?text=Architecture+Diagram)

L'architecture du projet est composée des éléments suivants :

- **Frontend** : Interface utilisateur HTML/CSS/JS servie par Nginx
- **Backend** : API REST développée avec Express.js
- **Base de données** : MySQL hébergée sur RDS
- **Kubernetes** : Cluster EKS pour l'orchestration des conteneurs
- **Services annexes** : SonarQube, GitHub Runner, Prometheus/Grafana

Pour plus de détails, consultez la [documentation d'architecture](./docs/architecture.md).

## Environnements

Le projet est déployé sur trois environnements distincts :

- **Development** : Pour le développement et les tests unitaires
- **Staging** : Pour les tests d'intégration et la validation
- **Production** : Pour les utilisateurs finaux

Pour plus de détails, consultez la [documentation des environnements](./docs/environments.md).

## Déploiement automatisé

Le déploiement complet de l'infrastructure et de l'application est entièrement automatisé via le pipeline CI/CD GitHub Actions.

### Prérequis

Configurer le secret GitHub suivant :
```
AWS_CREDENTIALS_BASE64
```

Ce secret doit contenir un fichier JSON encodé en base64 avec vos credentials AWS :
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

### Lancement du déploiement

Pour déclencher un déploiement complet :

1. Accédez à l'onglet "Actions" du dépôt GitHub
2. Sélectionnez le workflow "CI/CD Pipeline"
3. Cliquez sur "Run workflow"
4. Sélectionnez la branche et l'environnement souhaités
5. Cliquez sur "Run workflow"

Le pipeline créera automatiquement l'infrastructure backend Terraform (bucket S3 et table DynamoDB) avant de déployer l'infrastructure.

### Nettoyage des ressources

Si vous avez besoin de supprimer toutes les ressources AWS créées par le projet :

1. Accédez à l'onglet "Actions" du dépôt GitHub
2. Sélectionnez le workflow "AWS Resources Cleanup"
3. Cliquez sur "Run workflow"
4. Tapez "SUPPRIMER" dans le champ de confirmation
5. Sélectionnez la région AWS à nettoyer
6. Cliquez sur "Run workflow"

Pour plus de détails, consultez la [documentation de nettoyage](./docs/cleanup.md).

### Récupération des informations de déploiement

Après l'exécution du pipeline, vous pouvez télécharger les artifacts suivants :

- **terraform-outputs** : Contient les outputs Terraform (IPs, endpoints, etc.)
- **credentials** : Contient la clé SSH privée et le mot de passe de la base de données
- **credentials-updated** : Contient également le token GitHub Runner
- **deployment-report** : Rapport complet du déploiement

Pour plus de détails, consultez la [documentation d'automatisation](./docs/automation.md).

## Structure du projet

```
projet-c/
├── .github/workflows/    # Pipeline CI/CD
├── backend/              # API Express.js
├── database/             # Scripts SQL
├── docs/                 # Documentation complète
├── frontend/             # Interface utilisateur
├── infra/                # Infrastructure as Code
│   ├── ansible/          # Configuration des serveurs
│   ├── scripts/          # Scripts utilitaires
│   └── terraform/        # Définition de l'infrastructure
├── kubernetes/           # Manifestes Kubernetes
│   └── environments/     # Configurations par environnement
└── monitoring/           # Configuration du monitoring
```