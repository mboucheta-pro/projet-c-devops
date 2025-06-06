#!/bin/bash
# Script pour nettoyer l'état Terraform des ressources qui n'existent plus

echo "Vérification des ressources dans l'état Terraform..."

# Récupérer la liste des ressources dans l'état
RESOURCES=$(terraform state list)

# Vérifier chaque ressource
for resource in $RESOURCES; do
  echo "Vérification de la ressource: $resource"
  terraform state show "$resource" &>/dev/null 2&1
  if [ $? -ne 0 ]; then
    echo "La ressource $resource semble être en erreur, tentative de suppression de l'état..."
    terraform state rm "$resource"
  fi
done

echo "Nettoyage de l'état terminé"