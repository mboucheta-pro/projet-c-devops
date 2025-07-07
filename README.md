# Projet DevOps

## Présentation

Ce projet permet de déployer et configurer automatiquement une infrastructure Cloud (Azure), incluant Jenkins, SonarQube, leurs agents et bases SQL, à l’aide de Terraform, Ansible, scripts shell et GitHub Actions.

---

## Table des matières

- [Architecture](#architecture)
- [Prérequis](#prérequis)
- [Structure du projet](#structure-du-projet)
- [Déploiement de l’infrastructure](#déploiement-de-linfrastructure)
- [Configuration des services](#configuration-des-services)
- [CI/CD](#cicd)
- [Gestion des secrets](#gestion-des-secrets)
- [Sécurité & bonnes pratiques](#sécurité--bonnes-pratiques)
- [Dépannage](#dépannage)
- [Annexes](#annexes)

---

## Architecture

- **Cloud Provider** : Azure (ressources RG, SQL, VNet, etc.)
- **Provisioning** : Terraform (modules internes et registry SNCF)
- **Configuration** : Ansible (playbooks pour Jenkins, agents, SonarQube)
- **Automatisation** : Scripts shell pour orchestrer les étapes
- **CI/CD** : GitHub Actions (workflows pour build, test, déploiement)
- **Secrets** : Azure Key Vault

---

## Prérequis

- Accès Azure avec droits suffisants (création RG, SQL, VNet, Key Vault)
- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) >= 2.9
- [Azure CLI](https://docs.microsoft.com/fr-fr/cli/azure/install-azure-cli)
- [jq](https://stedolan.github.io/jq/)
- Accès au repository GitHub avec secrets configurés

---

## Structure du projet

```
.
├── infra/
│   ├── terraform/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── ...
│   └── ansible/
│       ├── playbook-jenkins.yml
│       ├── playbook-jenkins-agent.yml
│       ├── playbook-sonarqube.yml
│       └── roles/
├── scripts/
│   ├── deploy.sh
│   ├── destroy.sh
│   └── clean-secrets.sh
├── .github/
│   └── workflows/
│       └── ci.yml
├── docs/
│   ├── architecture.md
│   ├── troubleshooting.md
│   └── security.md
└── README.md
```

---

## Déploiement de l’infrastructure

```sh
cd infra/terraform
terraform init
terraform plan -out=planfile
terraform apply "planfile"
```

Pour détruire :
```sh
terraform destroy
```

---

## Configuration des services

```sh
cd infra/ansible
ansible-playbook -i inventory.ini playbook-jenkins.yml
ansible-playbook -i inventory.ini playbook-jenkins-agent.yml
ansible-playbook -i inventory.ini playbook-sonarqube.yml
```

---

## CI/CD

Le workflow `.github/workflows/ci.yml` automatise :
- L’initialisation, validation, plan et apply Terraform
- La configuration Ansible
- La destruction de l’infrastructure
- La gestion des secrets

---

## Gestion des secrets

- **Stockage** : Azure Key Vault
- **Accès** : Les playbooks Ansible et scripts shell récupèrent les secrets via Azure CLI.
- **Sécurité** : Les secrets ne sont jamais affichés dans les logs.

---

## Sécurité & bonnes pratiques

- Restreindre les accès SSH dans les security groups (éviter `0.0.0.0/0`).
- Ne jamais exposer de secrets dans les outputs, artefacts ou logs.
- Utiliser `set -euo pipefail` dans les scripts shell pour arrêter en cas d’erreur.
- Vérifier la présence des outils (`terraform`, `az`, `ansible`, `jq`) avant exécution.

---

## Dépannage

- **Terraform** : vérifier les droits Azure et la configuration du backend.
- **Ansible** : vérifier la connectivité SSH et la présence des variables d’environnement.
- **Scripts** : ajouter `set -x` pour le debug.
- **GitHub Actions** : consulter les logs détaillés dans l’onglet Actions du repository.

---

## Annexes

- [docs/architecture.md](docs/architecture.md) : Description détaillée de l’architecture
- [docs/troubleshooting.md](docs/troubleshooting.md) : Guide de dépannage
- [docs/security.md](docs/security.md) : Bonnes pratiques de sécurité

---

## Contact

Pour toute question ou contribution, ouvrir une issue sur le repository GitHub ou contacter l’équipe DevOps.
