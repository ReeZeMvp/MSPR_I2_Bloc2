# MSPR TPRE961 - Infrastructure Kubernetes (PoC COGIP)

PoC d'infrastructure Kubernetes pour la COGIP : deploiement de l'ERP Odoo sur un cluster K3s, provisionne en Infrastructure as Code sur VMware vSphere.

## Stack technique

| Composant | Technologie |
|-----------|------------|
| Hyperviseur | VMware ESXi 6.7 + vCenter |
| OS | Ubuntu Server 24.04 LTS |
| Template VM | Packer (builder vsphere-iso) |
| Provisionnement | Terraform (provider vSphere) |
| Configuration | Ansible |
| Kubernetes | K3s (1 control-plane + 2 workers) |
| Application | Odoo 17.0 (image officielle Docker Hub) |
| Base de donnees | PostgreSQL 16 (image officielle Docker Hub) |
| Ingress | Traefik (integre a K3s) |
| Deploiement app | Helm (chart custom) |

## Architecture

```
VM Admin (192.168.1.46)
  |-- Packer  --> Template VM sur vCenter
  |-- Terraform --> Clone 3 VMs
  |-- Ansible --> Configure K3s + deploie Odoo

Cluster K3s :
  k3s-cp  (192.168.1.48) - Control-plane + Traefik Ingress
  k3s-w1  (192.168.1.49) - Worker
  k3s-w2  (192.168.1.50) - Worker

Pods (namespace odoo) :
  Odoo 17.0 --> port 8069 --> Service ClusterIP --> Ingress Traefik --> port 80
  PostgreSQL 16 --> port 5432
```

## Prerequis

- Serveur ESXi 6.7 avec vCenter
- ISO Ubuntu Server 24.04 sur le datastore
- VM admin Ubuntu avec : Packer, Terraform, Ansible, xorriso
- Cle SSH generee (`ssh-keygen -t rsa -b 4096`)

## Deploiement

### 1. Packer - Creation du template

```bash
cd packer/
cp variables.pkrvars.hcl.example variables.pkrvars.hcl
# Editer variables.pkrvars.hcl avec tes valeurs
# Generer le hash du mot de passe : mkpasswd --method=SHA-512 --rounds=4096 "K3s@MSPR2025!"
# Remplacer le hash dans http/user-data

packer init ubuntu-k3s.pkr.hcl
packer build -var-file=variables.pkrvars.hcl ubuntu-k3s.pkr.hcl
```

### 2. Terraform - Deploiement des 3 VMs

```bash
cd terraform/
cp terraform.tfvars.example terraform.tfvars
# Editer terraform.tfvars avec tes valeurs

terraform init
terraform plan
terraform apply
```

### 3. Ansible - Configuration et deploiement

```bash
cd ansible/
# Editer inventory.ini avec les IPs de tes VMs
# Copier la cle SSH : ssh-copy-id admk3s@<IP>

ansible-playbook playbooks/01-prepare-nodes.yml -i inventory.ini
ansible-playbook playbooks/02-deploy-k3s-server.yml -i inventory.ini
ansible-playbook playbooks/03-deploy-k3s-agents.yml -i inventory.ini
ansible-playbook playbooks/04-deploy-odoo.yml -i inventory.ini
```

### 4. Acces a Odoo

En local : http://192.168.1.48

Depuis l'exterieur : configurer une regle de port forwarding sur le routeur (port 80 -> 192.168.1.48:80).

## Arborescence

```
mspr-infra/
|-- packer/
|   |-- ubuntu-k3s.pkr.hcl
|   |-- variables.pkrvars.hcl.example
|   |-- http/
|       |-- user-data
|       |-- meta-data
|-- terraform/
|   |-- main.tf
|   |-- variables.tf
|   |-- terraform.tfvars.example
|   |-- outputs.tf
|-- ansible/
|   |-- ansible.cfg
|   |-- inventory.ini
|   |-- playbooks/
|       |-- 01-prepare-nodes.yml
|       |-- 02-deploy-k3s-server.yml
|       |-- 03-deploy-k3s-agents.yml
|       |-- 04-deploy-odoo.yml
|-- helm-odoo/
|   |-- Chart.yaml
|   |-- values.yaml
|   |-- templates/
|       |-- manifests.yaml
|-- .gitignore
|-- README.md
```

## Equipe

- Agathe ALVES TAVARES
- Anthony JERONIMO
- Steeve PARIS
- Lucas RAGOT
- Nicolas ZEKRI

## Note sur Helm

Le chart Bitnami officiel pour Odoo n'etait pas utilisable dans notre contexte : migration des images vers un registry prive (registry.bitnami.com) inaccessible depuis notre reseau, tags d'images inexistants sur Docker Hub, et mecanisme de verification des images bloquant. Nous avons cree un chart Helm custom utilisant les images officielles Docker Hub (odoo:17.0 et postgres:16), ce qui garantit un deploiement fiable et reproductible.
