# Architecture du Projet-C

## Vue d'ensemble

L'architecture du Projet-C est conçue pour être robuste, évolutive et optimisée en termes de coûts. Elle suit les bonnes pratiques de l'architecture cloud moderne et des microservices.

## Diagramme d'architecture

```
                                   ┌─────────────────┐
                                   │                 │
                                   │  AWS Cloud      │
                                   │                 │
┌─────────────┐                    │  ┌───────────┐  │
│             │                    │  │           │  │
│  Utilisateur│ ───────────────────┼─▶│    ALB    │  │
│             │                    │  │           │  │
└─────────────┘                    │  └─────┬─────┘  │
                                   │        │        │
                                   │        ▼        │
                                   │  ┌───────────┐  │
                                   │  │           │  │
                                   │  │    EKS    │  │
                                   │  │           │  │
                                   │  └───┬───┬───┘  │
                                   │      │   │      │
                             ┌─────┴──────┘   └──────┴─────┐
                             │                            │
                             ▼                            ▼
                      ┌────────────┐                ┌────────────┐
                      │            │                │            │
                      │  Frontend  │                │  Backend   │
                      │  (Nginx)   │                │ (Express.js)│
                      │            │                │            │
                      └────────────┘                └──────┬─────┘
                                                           │
                                                           │
                                                           ▼
                                                    ┌────────────┐
                                                    │            │
                                                    │    RDS     │
                                                    │  (MySQL)   │
                                                    │            │
                                                    └────────────┘
```

## Composants principaux

### Infrastructure Cloud (AWS)

- **VPC** : Réseau virtuel isolé avec subnets publics et privés
- **EKS** : Service Kubernetes géré pour l'orchestration des conteneurs
- **RDS** : Service de base de données relationnelle pour MySQL
- **ECR** : Registry pour les images Docker
- **ALB** : Load balancer pour distribuer le trafic

### Composants applicatifs

- **Frontend** : Application web servie par Nginx
- **Backend** : API REST développée avec Express.js
- **Base de données** : MySQL pour le stockage des données

### Services annexes

- **GitHub Runner** : Pour l'exécution des workflows CI/CD
- **SonarQube** : Pour l'analyse de la qualité du code
- **Prometheus/Grafana** : Pour le monitoring

## Flux de données

1. L'utilisateur accède à l'application via l'ALB
2. L'ALB route les requêtes vers le frontend ou le backend selon le chemin
3. Le frontend affiche l'interface utilisateur et communique avec le backend
4. Le backend traite les requêtes et interagit avec la base de données
5. Les métriques sont collectées par Prometheus et visualisées dans Grafana

## Sécurité

- Trafic HTTPS entre l'utilisateur et l'ALB
- Communication sécurisée entre les composants
- Base de données dans un subnet privé
- Secrets gérés via Kubernetes Secrets et AWS Secrets Manager

## Haute disponibilité

- Déploiement sur plusieurs zones de disponibilité
- Réplicas multiples pour les composants applicatifs
- Auto-scaling basé sur la charge

## Optimisation des coûts

- Instances Spot pour les nœuds EKS
- Dimensionnement approprié des ressources
- Utilisation d'instances t3a pour un meilleur rapport performance/coût