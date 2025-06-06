# Environnements de déploiement

Le Projet-C utilise trois environnements distincts pour le développement, les tests et la production. Cette approche permet de séparer clairement les différentes étapes du cycle de vie de l'application.

## Vue d'ensemble des environnements

| Caractéristique | Development | Staging | Production |
|----------------|-------------|---------|------------|
| **Objectif** | Développement et tests unitaires | Tests d'intégration et validation | Environnement de production |
| **Namespace Kubernetes** | `development` | `staging` | `production` |
| **Base de données** | `appdb_dev` | `appdb_staging` | `appdb_prod` |
| **Branche Git** | Feature branches | `develop` | `main` |
| **Couleur UI** | Vert | Jaune | Rouge |
| **Stabilité** | Expérimental | Stable | Très stable |
| **Accès** | Équipe de développement | Équipe de développement et QA | Utilisateurs finaux |

## Configuration spécifique par environnement

### Development

```yaml
# Extrait de la configuration Kubernetes
apiVersion: v1
kind: ConfigMap
metadata:
  name: backend-config
  namespace: development
data:
  NODE_ENV: "development"
  DB_HOST: "projet-c-db.cluster-xyz.eu-west-3.rds.amazonaws.com"
  DB_NAME: "appdb_dev"
  DB_USER: "dbadmin"
```

- **Caractéristiques** :
  - Logs verbeux
  - Rechargement automatique du code
  - Données de test
  - Pas de mise en cache

### Staging

```yaml
# Extrait de la configuration Kubernetes
apiVersion: v1
kind: ConfigMap
metadata:
  name: backend-config
  namespace: staging
data:
  NODE_ENV: "staging"
  DB_HOST: "projet-c-db.cluster-xyz.eu-west-3.rds.amazonaws.com"
  DB_NAME: "appdb_staging"
  DB_USER: "dbadmin"
```

- **Caractéristiques** :
  - Configuration proche de la production
  - Données de test contrôlées
  - Tests de performance
  - Tests d'intégration

### Production

```yaml
# Extrait de la configuration Kubernetes
apiVersion: v1
kind: ConfigMap
metadata:
  name: backend-config
  namespace: production
data:
  NODE_ENV: "production"
  DB_HOST: "projet-c-db.cluster-xyz.eu-west-3.rds.amazonaws.com"
  DB_NAME: "appdb_prod"
  DB_USER: "dbadmin"
```

- **Caractéristiques** :
  - Optimisé pour les performances
  - Logs minimaux
  - Mise en cache activée
  - Données réelles

## Flux de déploiement

Le flux de déploiement entre les environnements suit le modèle GitFlow :

1. Les développeurs travaillent sur des branches de fonctionnalités
2. Les branches de fonctionnalités sont fusionnées dans `develop` après revue
3. La branche `develop` est déployée automatiquement dans l'environnement de staging
4. Après validation en staging, `develop` est fusionné dans `main`
5. La branche `main` est déployée automatiquement en production

## Gestion des secrets

Les secrets sont gérés différemment selon l'environnement :

- **Development** : Secrets stockés dans Kubernetes avec des valeurs de développement
- **Staging** : Secrets stockés dans Kubernetes avec des valeurs de test
- **Production** : Secrets stockés dans AWS Secrets Manager et injectés dans Kubernetes

## Tests et validation

Chaque environnement a son propre ensemble de tests :

- **Development** : Tests unitaires et tests de développement
- **Staging** : Tests d'intégration, tests de performance, tests de régression
- **Production** : Tests de smoke, monitoring

## Accès aux environnements

| Environnement | URL | Accès |
|--------------|-----|-------|
| Development | https://dev.projet-c.example.com | Équipe de développement |
| Staging | https://staging.projet-c.example.com | Équipe de développement et QA |
| Production | https://projet-c.example.com | Public |