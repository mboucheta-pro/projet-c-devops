# Bonnes pratiques Terraform

Ce document présente les bonnes pratiques et les solutions aux problèmes courants lors de l'utilisation de Terraform dans ce projet.

## Gestion des ressources existantes

### Problème
Lorsque des ressources existent déjà dans AWS mais ne sont pas dans l'état Terraform, vous pouvez rencontrer des erreurs comme :
- `Error: ... already exists`
- `InvalidConfigurationRequest: One or more security groups are invalid`

### Solution
Nous avons mis en place plusieurs mécanismes pour gérer ce problème :

1. **Script d'import automatique** : Le script `import.sh` tente d'importer les ressources existantes dans l'état Terraform.

2. **Script de nettoyage d'état** : Le script `state_cleanup.sh` supprime de l'état Terraform les ressources qui n'existent plus.

3. **Blocs lifecycle** : Nous utilisons des blocs lifecycle pour gérer les ressources sensibles :
   - `prevent_destroy = true` : Empêche la suppression accidentelle de ressources critiques
   - `ignore_changes = [...]` : Ignore certains changements qui pourraient provoquer des recréations inutiles
   - `create_before_destroy = true` : Crée la nouvelle ressource avant de détruire l'ancienne

## Optimisations de coûts

1. **Instances Spot** pour les nœuds EKS
2. **Single NAT Gateway** au lieu d'une par zone de disponibilité
3. **Volumes gp3** au lieu de gp2 (meilleur rapport coût/performance)
4. **Instances t3a** (AMD) moins coûteuses que les t3 (Intel)

## Sécurité

1. **Chiffrement** des données au repos (S3, RDS)
2. **Groupes de sécurité** avec principe du moindre privilège
3. **Accès privé** pour les ressources sensibles (RDS, EKS)

## Résolution des problèmes courants

### Erreur de groupe de sécurité invalide pour l'ALB
```
Error: creating ELBv2 application Load Balancer: InvalidConfigurationRequest: One or more security groups are invalid
```

**Solution** : Vérifiez que le groupe de sécurité existe et qu'il est correctement référencé. Notre script d'import tente d'importer ce groupe de sécurité automatiquement.

### Erreur de groupe de sous-réseaux RDS déjà existant
```
Error: creating RDS DB Subnet Group: DBSubnetGroupAlreadyExists: The DB subnet group already exists.
```

**Solution** : Nous avons ajouté `lifecycle { prevent_destroy = true }` pour ce groupe et notre script d'import tente de l'importer automatiquement.

### Erreur de groupe de logs CloudWatch déjà existant
```
Error: creating CloudWatch Logs Log Group: ResourceAlreadyExistsException: The specified log group already exists
```

**Solution** : Notre script d'import tente d'importer ce groupe de logs automatiquement.

## Commandes utiles

### Importer manuellement une ressource
```bash
terraform import aws_db_subnet_group.default projet-c-db-subnet-group
```

### Supprimer une ressource de l'état sans la détruire
```bash
terraform state rm aws_db_subnet_group.default
```

### Voir les différences entre l'état et la configuration
```bash
terraform plan
```