Objectif : Construire une pipeline de CI/CD permettant de déployer une application sur une infrastructure hébergée dans le Cloud
 
Application
- un front, un back et une base de données
- projet multi langages (React, Node, PHP)

 
CI/CD (avec github)
- tests unitaires
- build
- push de l'artifact dans une registry (ghcr.io)
- gestion as code de l'infrastructure
- déploiement de l'application

Monitoring:
- monitoring de l'application (nombre de requêtes, latence, %age de requêtes en erreur, etc...)
- monitoring de l'infrastructure (consommation RAM, CPU, nombre de pods, etc...)
 
Technologies obligatoires
- cloud AWS
- Terraform
- Ansible
- Docker
- Kubernetes
 
Tous les secrets utilisés par l'application, l'infrastructure et la CI/CD devront être gérés à l'aide d'un outil de gestion des secrets.
