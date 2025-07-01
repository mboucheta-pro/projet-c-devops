# Utilisation du Bastion Host

Ce document explique comment utiliser le bastion host pour accéder de manière sécurisée aux instances et à la base de données.

## Prérequis

- Clé SSH privée correspondant à la clé publique utilisée pour déployer l'infrastructure
- Client SSH (OpenSSH, PuTTY, etc.)
- Client MySQL pour accéder à la base de données

## Connexion au bastion

```bash
ssh -i chemin/vers/cle_privee ubuntu@<BASTION_IP>
```

Remplacez `<BASTION_IP>` par l'adresse IP du bastion disponible dans les outputs Terraform.

## Connexion aux instances via le bastion

### Méthode 1: Utilisation de ProxyJump (recommandée)

```bash
ssh -i chemin/vers/cle_privee -J ubuntu@<BASTION_IP> ubuntu@<INSTANCE_PRIVATE_IP>
```

Remplacez `<INSTANCE_PRIVATE_IP>` par l'adresse IP privée de l'instance cible.

### Méthode 2: Configuration du fichier SSH config

Ajoutez les lignes suivantes à votre fichier `~/.ssh/config` :

```
Host bastion
    HostName <BASTION_IP>
    User ubuntu
    IdentityFile chemin/vers/cle_privee

Host instance-*
    ProxyJump bastion
    User ubuntu
    IdentityFile chemin/vers/cle_privee

Host instance-github-runner
    HostName <GITHUB_RUNNER_PRIVATE_IP>

Host instance-sonarqube
    HostName <SONARQUBE_PRIVATE_IP>

Host instance-monitoring
    HostName <MONITORING_PRIVATE_IP>
```

Puis connectez-vous simplement avec :

```bash
ssh instance-github-runner
```

## Connexion à la base de données via le bastion

### Méthode 1: Tunnel SSH

```bash
ssh -i chemin/vers/cle_privee -L 3306:<DB_ENDPOINT>:3306 ubuntu@<BASTION_IP>
```

Puis, dans un autre terminal :

```bash
mysql -h 127.0.0.1 -u <DB_USERNAME> -p
```

### Méthode 2: Connexion directe depuis le bastion

1. Connectez-vous d'abord au bastion :

```bash
ssh -i chemin/vers/cle_privee ubuntu@<BASTION_IP>
```

2. Puis, depuis le bastion, connectez-vous à la base de données :

```bash
mysql -h <DB_ENDPOINT> -u <DB_USERNAME> -p
```

## Bonnes pratiques de sécurité

1. Limitez l'accès SSH au bastion à vos adresses IP en modifiant le groupe de sécurité
2. Utilisez des clés SSH fortes (RSA 4096 bits ou ED25519)
3. Désactivez l'authentification par mot de passe sur le bastion
4. Activez la journalisation des connexions SSH
5. Mettez régulièrement à jour le système d'exploitation du bastion