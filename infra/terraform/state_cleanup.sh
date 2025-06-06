#!/bin/bash
# Script pour nettoyer l'état Terraform des ressources qui n'existent plus

# Vérifier si des ressources sont en erreur dans l'état
terraform state list | while read resource; do
  echo "Vérification de la ressource: $resource"
  terraform state show "$resource" &>/dev/null
  if [ $? -ne 0 ]; then
    echo "La ressource $resource semble être en erreur, tentative de suppression de l'état..."
    terraform state rm "$resource"
  fi
done

echo "Nettoyage de l'état terminé"