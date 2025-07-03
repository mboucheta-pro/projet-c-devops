# GitHub Runner Auto-Enregistré

## Configuration requise

### Token GitHub
Créez un Personal Access Token avec les permissions :
- `repo` (accès complet au repository)
- `admin:repo_hook` (gestion des webhooks)

### Variables Terraform
Configurez dans `terraform.tfvars` :
```hcl
github_token = "ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
github_repo  = "votre-username/votre-repo"
```

## Fonctionnalités

- **Instance** : t3a.medium Ubuntu 24.04
- **Outils** : Docker, Node.js, Python3, Git, Yarn
- **Labels** : `self-hosted`, `linux`, `x64`, `aws`
- **Auto-enregistrement** : Automatique via API GitHub

## Déploiement

```bash
terraform init
terraform plan
terraform apply
```

Vérifiez dans GitHub > Settings > Actions > Runners