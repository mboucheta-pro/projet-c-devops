# Architecture technique – Projet DevOps

## Vue d’ensemble

L’infrastructure cible déployée sur Azure comprend :
- Un Resource Group dédié
- Un VNet avec sous-réseaux publics/privés
- Un serveur SQL Azure
- Des machines virtuelles pour Jenkins, ses agents et SonarQube
- Un Key Vault pour la gestion des secrets

## Schéma

```
[Internet]
   |
[Azure Load Balancer]
   |
[VM Jenkins] -- [VM SonarQube]
   |
[VM Jenkins Agent(s)]
   |
[Azure SQL Database]
   |
[Azure Key Vault]
```

## Flux réseau

- Accès SSH restreint à certaines IPs
- Jenkins et SonarQube accessibles via ports spécifiques
- Communication interne entre les VMs et la base SQL

## Modules Terraform utilisés

- Modules internes pour la gestion des RG, VNet, SQL, VM
- Modules registry SNCF pour la conformité

## Points de vigilance

- Sécurité réseau (NSG)
- Gestion des identités (Managed Identity, RBAC)
- Stockage des secrets (Key Vault)
