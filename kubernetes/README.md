# Déploiement Kubernetes pour Projet-C

Ce répertoire contient les fichiers de configuration Kubernetes pour déployer l'application Projet-C sur un cluster EKS.

## Structure des fichiers

- `backend-deployment.yaml` : Déploiement et service pour le backend Express.js
- `frontend-deployment.yaml` : Déploiement et service pour le frontend Nginx
- `configmap.yaml` : Configuration Nginx pour le routage des requêtes
- `ingress.yaml` : Configuration de l'Ingress pour exposer l'application

## Déploiement

Pour déployer l'application sur le cluster EKS :

```bash
# Assurez-vous d'avoir configuré kubectl pour votre cluster EKS
aws eks update-kubeconfig --name projet-c-cluster --region eu-west-3

# Appliquer les configurations
kubectl apply -f configmap.yaml
kubectl apply -f backend-deployment.yaml
kubectl apply -f frontend-deployment.yaml
kubectl apply -f ingress.yaml

# Vérifier le déploiement
kubectl get pods
kubectl get services
kubectl get ingress
```

## Architecture

L'application est déployée avec les composants suivants :

1. **Backend** :
   - Déploiement avec 2 réplicas pour la haute disponibilité
   - Ressources limitées pour optimiser les coûts
   - Probes de santé pour assurer la fiabilité

2. **Frontend** :
   - Déploiement avec 2 réplicas
   - Configuration Nginx via ConfigMap
   - Routage des requêtes /api/ vers le backend

3. **Ingress** :
   - Utilisation d'un AWS ALB pour exposer l'application
   - Routage basé sur les chemins d'URL

## Optimisations

- Ressources CPU et mémoire limitées pour réduire les coûts
- Probes de santé pour assurer la fiabilité
- Configuration de scaling automatique possible via HPA (non inclus)