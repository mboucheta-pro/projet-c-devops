# Bonnes pratiques de sécurité – Projet DevOps

## Gestion des secrets

- Stocker tous les secrets dans Azure Key Vault.
- Ne jamais afficher de secrets dans les logs, outputs ou artefacts.
- Utiliser des identités managées pour accéder au Key Vault.

## Accès réseau

- Restreindre les accès SSH à des IPs de confiance.
- Limiter l’exposition des ports Jenkins/SonarQube.
- Utiliser des NSG pour filtrer le trafic.

## Droits et identités

- Privilégier le principe du moindre privilège (RBAC Azure).
- Ne pas utiliser de comptes personnels pour les déploiements automatisés.

## Audit et logs

- Activer le diagnostic sur les ressources critiques.
- Surveiller les accès au Key Vault et aux VMs.

## Mise à jour

- Maintenir à jour les outils (`terraform`, `az`, `ansible`).
- Appliquer les correctifs de sécurité sur les VMs déployées.
