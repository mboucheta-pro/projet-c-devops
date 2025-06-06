# Documentation Projet-C

Cette documentation regroupe toutes les informations nécessaires pour comprendre, déployer et maintenir le projet.

## Table des matières

1. [Architecture](./architecture.md)
2. [Infrastructure](./README.md#infrastructure)
3. [Application](./README.md#application)
4. [Environnements](./environments.md)
5. [Automatisation](./automation.md)
6. [Pipeline CI/CD](./README.md#pipeline-cicd)
7. [Monitoring](./README.md#monitoring)
8. [Sécurité](./README.md#sécurité)
9. [Guide de déploiement](./README.md#guide-de-déploiement)

## Architecture

![Architecture](https://via.placeholder.com/800x400?text=Architecture+Diagram)

L'architecture du projet est composée des éléments suivants :

- **Frontend** : Interface utilisateur HTML/CSS/JS servie par Nginx
- **Backend** : API REST développée avec Express.js
- **Base de données** : MySQL hébergée sur RDS
- **Kubernetes** : Cluster EKS pour l'orchestration des conteneurs
- **Services annexes** : SonarQube, GitHub Runner, Prometheus/Grafana

Pour plus de détails, consultez la [documentation d'architecture](./architecture.md).

## Infrastructure

L'infrastructure est déployée sur AWS à l'aide de Terraform et comprend :

### Composants principaux

- **VPC** avec subnets publics et privés
- **Cluster EKS** avec nœuds Spot pour optimiser les coûts
- **Base de données RDS MySQL**
- **Instances EC2** pour GitHub Runner, SonarQube et Monitoring

### Optimisations de coûts

- Utilisation d'instances t3a (AMD) moins coûteuses que les t3 (Intel)
- Single NAT Gateway pour réduire les coûts de NAT
- Instances Spot pour les nœuds EKS
- Volumes gp3 au lieu de gp2 (meilleur rapport coût/performance)

### Déploiement de l'infrastructure

L'infrastructure est entièrement déployée via le pipeline CI/CD. Pour plus de détails, consultez la [documentation d'automatisation](./automation.md).

## Application

L'application est une application web simple avec un frontend et un backend qui interagissent avec une base de données MySQL.

### Backend (Node.js/Express)

- API REST développée avec Express.js
- Connexion à la base de données MySQL
- Endpoints pour la gestion des items

### Frontend (HTML/CSS/JS + Nginx)

- Interface utilisateur simple
- Affichage des données depuis l'API
- Formulaire pour ajouter des items
- Styles différents selon l'environnement

### Base de données

- MySQL hébergée sur RDS
- Tables et données initiales pour chaque environnement

## Environnements

Le projet est déployé sur trois environnements distincts :

- **Development** : Pour le développement et les tests unitaires
- **Staging** : Pour les tests d'intégration et la validation
- **Production** : Pour les utilisateurs finaux

Pour plus de détails, consultez la [documentation des environnements](./environments.md).

## Pipeline CI/CD

Le pipeline CI/CD est implémenté avec GitHub Actions et comprend les étapes suivantes :

1. **Infrastructure** : Déploiement de l'infrastructure avec Terraform
2. **Configuration** : Configuration des serveurs avec Ansible
3. **Build et test** : Compilation et tests unitaires
4. **Scan de sécurité** : Analyse des vulnérabilités avec Trivy
5. **Build et push** : Construction des images Docker et envoi vers ECR
6. **Déploiement** : Déploiement sur le cluster EKS

Pour plus de détails, consultez la [documentation d'automatisation](./automation.md).

## Monitoring

Le monitoring est assuré par Prometheus et Grafana :

### Métriques surveillées

- **Application** :
  - Nombre de requêtes
  - Latence
  - Pourcentage de requêtes en erreur

- **Infrastructure** :
  - Consommation RAM
  - Consommation CPU
  - Nombre de pods

### Accès aux dashboards

- Prometheus : http://monitoring-ip:9090
- Grafana : http://monitoring-ip:3000 (admin/admin)

## Sécurité

### Gestion des secrets

- Secrets Kubernetes pour les credentials de la base de données
- Secrets GitHub pour les credentials AWS

### Scan de sécurité

- Trivy pour l'analyse des vulnérabilités des images Docker
- SonarQube pour l'analyse de la qualité et de la sécurité du code

### Réseau

- VPC avec subnets privés pour les composants sensibles
- Groupes de sécurité restrictifs

## Guide de déploiement

### Déploiement automatisé

Pour déclencher un déploiement complet via le pipeline CI/CD :

1. Accédez à l'onglet "Actions" du dépôt GitHub
2. Sélectionnez le workflow "CI/CD Pipeline"
3. Cliquez sur "Run workflow"
4. Sélectionnez la branche et l'environnement souhaités
5. Cliquez sur "Run workflow"

Pour plus de détails, consultez la [documentation d'automatisation](./automation.md).