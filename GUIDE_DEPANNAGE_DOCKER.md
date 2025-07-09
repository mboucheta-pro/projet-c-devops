# 🔧 Guide de dépannage des conflits APT Docker

## ❌ Erreur rencontrée

```
E:Conflicting values set for option Signed-By regarding source https://download.docker.com/linux/ubuntu/ noble: /etc/apt/keyrings/docker.gpg != , E:The list of sources could not be read.
```

## 🎯 Solutions par ordre de préférence

### **Solution 1: Script de nettoyage Ansible ad-hoc (Recommandé)**

```bash
cd /Users/7408122G/GIT.LOCAL/projet-c-devops/scripts
./ansible_cleanup_docker.sh jenkins-agent
```

**Avantages**: Automatisé, utilise Ansible, traçabilité

### **Solution 2: Playbook Jenkins Agent corrigé**

Le playbook a été mis à jour avec un nettoyage préventif au début :

```bash
cd /Users/7408122G/GIT.LOCAL/projet-c-devops/infra/ansible
ansible-playbook jenkins-agent-playbook.yml -i inventory
```

**Avantages**: Correction intégrée, évite les conflits futurs

### **Solution 3: Script de nettoyage manuel**

Si vous avez accès SSH direct au serveur :

```bash
# Copier le script sur le serveur
scp scripts/manual_cleanup_docker_repos.sh ubuntu@jenkins-agent-ip:~/

# Exécuter sur le serveur
ssh ubuntu@jenkins-agent-ip
sudo ./manual_cleanup_docker_repos.sh
```

**Avantages**: Contrôle total, diagnostic détaillé

### **Solution 4: Commandes manuelles directes**

En dernier recours, connexion SSH directe :

```bash
ssh ubuntu@jenkins-agent-ip

# Nettoyage complet
sudo rm -f /etc/apt/sources.list.d/docker*
sudo rm -f /etc/apt/trusted.gpg.d/docker*
sudo rm -f /etc/apt/keyrings/docker*
sudo sed -i '/docker/d' /etc/apt/sources.list
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*
sudo apt-get update

# Réinstallation propre
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker-official.list

sudo apt-get update
```

## 🔍 Diagnostic des problèmes

### **Vérifier l'état actuel**

```bash
# Via Ansible
ansible jenkins-agent -m shell -a "ls -la /etc/apt/sources.list.d/ | grep docker"
ansible jenkins-agent -m shell -a "ls -la /etc/apt/keyrings/ | grep docker"

# Ou en SSH direct
ssh ubuntu@jenkins-agent-ip "ls -la /etc/apt/sources.list.d/ | grep docker"
ssh ubuntu@jenkins-agent-ip "apt-get update 2>&1 | head -10"
```

### **Identifier les conflits**

```bash
# Rechercher les doublons de dépôts
grep -r "docker" /etc/apt/sources.list.d/
grep "docker" /etc/apt/sources.list

# Vérifier les clés GPG
ls -la /etc/apt/keyrings/docker*
ls -la /etc/apt/trusted.gpg.d/docker*
```

## 🛡️ Prévention des conflits futurs

### **1. Playbook amélioré**

Le playbook Jenkins agent inclut maintenant :
- ✅ Nettoyage préventif au début
- ✅ Gestion d'erreur avec `ignore_errors: yes`
- ✅ Double tentative de mise à jour APT
- ✅ Installation propre avec un seul fichier de dépôt

### **2. Bonnes pratiques**

```yaml
# ✅ Toujours nettoyer avant d'installer
- name: Nettoyer les anciens dépôts
  file:
    path: "/etc/apt/sources.list.d/{{ item }}"
    state: absent
  loop:
    - docker.list
    - docker-ce.list
    - docker-official.list

# ✅ Utiliser un seul fichier de dépôt
- name: Créer un seul dépôt Docker
  copy:
    dest: /etc/apt/sources.list.d/docker-official.list
    content: |
      deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu {{ ansible_distribution_release }} stable

# ✅ Gestion d'erreur systématique
- name: Mise à jour APT
  apt:
    update_cache: yes
  register: apt_result
  ignore_errors: yes
```

## 📋 Scripts de dépannage créés

### **`ansible_cleanup_docker.sh`**
- 🎯 Nettoyage via Ansible ad-hoc
- ✅ Automatisé et traçable
- ✅ Idéal pour environnements de production

### **`manual_cleanup_docker_repos.sh`**
- 🎯 Nettoyage manuel sur serveur
- ✅ Diagnostic détaillé
- ✅ Contrôle total du processus

### **`fix_templating_errors.sh`**
- 🎯 Diagnostic général des playbooks
- ✅ Test de syntaxe
- ✅ Détection de problèmes potentiels

## 🚀 Après la correction

### **1. Validation**

```bash
# Tester que Docker peut être installé
ansible jenkins-agent -m shell -a "apt-cache policy docker-ce"

# Ou en direct
ssh ubuntu@jenkins-agent-ip "apt-cache policy docker-ce"
```

### **2. Relancer le déploiement**

```bash
cd /Users/7408122G/GIT.LOCAL/projet-c-devops/infra/ansible
ansible-playbook jenkins-agent-playbook.yml -i inventory
```

### **3. Monitoring continu**

```bash
# Vérifier l'absence de conflits
./scripts/validate_jenkins.sh jenkins-agent-ip
```

## ⚠️ Points d'attention

1. **Versions Ubuntu**: Le conflit peut survenir avec Ubuntu Noble (24.04) - utilisez `$(lsb_release -cs)` pour détecter automatiquement

2. **Multiples installations**: Évitez de mélanger les méthodes d'installation Docker (snap, dépôt officiel, etc.)

3. **Permissions**: Toujours utiliser `sudo` pour les modifications APT

4. **Backup**: Sauvegarder `/etc/apt/sources.list.d/` avant modifications importantes

---

**Status**: ✅ **Solutions multiples disponibles** - Choisissez selon votre contexte (automatisé vs manuel, Ansible vs SSH direct)
