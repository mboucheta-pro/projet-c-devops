# Architecture de Sécurité

Ce document décrit l'architecture de sécurité mise en place pour le projet.

## Vue d'ensemble

L'architecture de sécurité repose sur plusieurs principes fondamentaux :

1. **Point d'entrée unique** : Tout le trafic externe passe par un Application Load Balancer (ALB)
2. **Accès SSH sécurisé** : Accès SSH uniquement via un bastion host
3. **Base de données privée** : Base de données non accessible publiquement
4. **Segmentation réseau** : Séparation claire entre les différents composants

## Composants de sécurité

### Application Load Balancer (ALB)

- Seul point d'entrée pour le trafic HTTP/HTTPS (ports 80/443)
- Terminaison SSL/TLS
- Redirection automatique HTTP vers HTTPS
- Routage intelligent vers frontend ou backend selon le chemin

### Bastion Host

- Seul serveur accessible en SSH depuis l'extérieur
- Point d'entrée unique pour l'administration
- Permet l'accès SSH aux autres instances
- Permet l'accès à la base de données pour l'administration

### Groupes de sécurité

1. **Groupe ALB**
   - Autorise les ports 80/443 depuis Internet
   - Communique avec les instances d'application

2. **Groupe Bastion**
   - Autorise le port 22 (SSH) depuis Internet
   - Communique avec toutes les instances et la base de données

3. **Groupe Instances**
   - Autorise le port 22 (SSH) uniquement depuis le bastion
   - Autorise les ports 80/443 uniquement depuis l'ALB
   - Autorise les ports internes (3000, 9000, 9090) uniquement depuis le VPC

4. **Groupe Base de données**
   - Autorise le port 3306 (MySQL) uniquement depuis les instances et le bastion
   - Aucun accès direct depuis Internet

### Base de données

- Déployée dans des sous-réseaux privés
- Non accessible publiquement
- Accès uniquement via les instances d'application ou le bastion

## Flux de trafic

1. **Trafic utilisateur**
   - Utilisateur → ALB (HTTPS) → Instances d'application

2. **Trafic administratif**
   - Administrateur → Bastion (SSH) → Instances/Base de données

## Bonnes pratiques implémentées

1. **Principe du moindre privilège**
   - Chaque composant n'a que les accès strictement nécessaires

2. **Défense en profondeur**
   - Plusieurs couches de sécurité (ALB, groupes de sécurité, sous-réseaux)

3. **Chiffrement en transit**
   - HTTPS pour le trafic utilisateur
   - SSH pour le trafic administratif

4. **Isolation des environnements**
   - Séparation claire entre développement, staging et production

## Recommandations supplémentaires

1. **Restriction des adresses IP**
   - Limiter l'accès SSH au bastion à des adresses IP spécifiques

2. **Rotation des clés**
   - Mettre en place une rotation régulière des clés SSH et des mots de passe

3. **Surveillance et alertes**
   - Configurer des alertes pour les tentatives d'accès non autorisées

4. **Mises à jour de sécurité**
   - Mettre en place un processus de mise à jour régulière des systèmes