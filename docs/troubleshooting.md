# Guide de dépannage – Projet DevOps

## Problèmes Terraform

- **Erreur d’authentification Azure**  
  Vérifier la connexion avec `az login` et les droits du service principal.

- **Erreur de backend**  
  Vérifier la configuration du backend (storage account, container, key).

- **Ressource déjà existante**  
  Utiliser `terraform state rm` pour supprimer la ressource du state si besoin.

## Problèmes Ansible

- **Connexion SSH refusée**  
  Vérifier la clé SSH, l’IP publique de la VM et la règle NSG.

- **Erreur de variable manquante**  
  Vérifier que toutes les variables d’environnement sont bien exportées.

## Problèmes scripts shell

- **Commande non trouvée**  
  Vérifier l’installation de `terraform`, `az`, `ansible`, `jq`.

- **Erreur de droits**  
  Lancer les scripts avec les droits suffisants (`chmod +x`).

## Problèmes CI/CD

- **Secrets non injectés**  
  Vérifier la configuration des secrets dans GitHub Actions.

- **Échec d’un job**  
  Consulter les logs détaillés dans l’onglet Actions.

## Astuces

- Ajouter `set -x` dans les scripts pour le debug.
- Utiliser `terraform plan` avant tout `apply`.
- Nettoyer les ressources avec `terraform destroy` en cas d’échec.
