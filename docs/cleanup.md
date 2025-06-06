# Nettoyage des ressources AWS

Ce document explique comment nettoyer toutes les ressources AWS créées par le projet.

## Option 1 : Utiliser le workflow GitHub Actions

La méthode la plus simple est d'utiliser le workflow GitHub Actions préconfiguré :

1. Accédez à l'onglet "Actions" du dépôt GitHub
2. Sélectionnez le workflow "AWS Resources Cleanup"
3. Cliquez sur "Run workflow"
4. Tapez "SUPPRIMER" dans le champ de confirmation
5. Cliquez sur "Run workflow"

Le workflow exécutera automatiquement le script de nettoyage avec les credentials AWS configurés.

## Option 2 : Exécuter le script manuellement

Si vous préférez exécuter le script manuellement :

1. Configurez vos credentials AWS :
   ```bash
   export AWS_ACCESS_KEY_ID=votre_access_key
   export AWS_SECRET_ACCESS_KEY=votre_secret_key
   export AWS_REGION=ca-central-1
   ```

2. Exécutez le script de nettoyage :
   ```bash
   chmod +x ./infra/scripts/cleanup.sh
   ./infra/scripts/cleanup.sh
   ```

## Ressources supprimées

Le script supprime les ressources suivantes :

- Clusters EKS et leurs groupes de nœuds
- Instances EC2
- Adresses IP élastiques (EIPs)
- Paires de clés SSH
- Bases de données RDS
- VPCs et leurs ressources associées :
  - Sous-réseaux
  - Groupes de sécurité
  - Tables de routage
  - Passerelles Internet
  - NAT Gateways

## Remarques importantes

- Le script attend 5 minutes entre la suppression des ressources principales et la suppression des VPCs pour permettre aux ressources dépendantes d'être correctement supprimées.
- Certaines ressources peuvent nécessiter une suppression manuelle si elles ont des dépendances complexes.
- Assurez-vous de ne pas avoir d'autres ressources importantes dans le même compte AWS qui pourraient être affectées par ce script.