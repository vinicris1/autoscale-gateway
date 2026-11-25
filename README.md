# k8s-autoscaling-gateway

Gateway com autoscaling rodando em Kubernetes, provisionado 100% com IaC e entregue por CI/CD.

O objetivo é demonstrar escala horizontal de pods (HPA/KEDA) e de nós (Karpenter) sob carga normal, picos e um ataque simulado (DoS), com tudo observável no Grafana.

> Projeto de portfólio em construção. Veja o [status](#status).

## Arquitetura

```
cliente / k6 ──► Traefik (rate limit por IP)
                     │
                     ▼
              API (encurtador de URL) ──► Redis
                     │
              kube-prometheus-stack + Grafana

Escala em dois níveis:
  pods  ── KEDA lê RPS / p95 no Prometheus e muda as réplicas da API e do Traefik
             │ pods novos sem espaço ficam Pending
             ▼
  nós   ── Karpenter cria ou remove EC2 spot conforme os pods Pending (só na AWS)
```

| Ambiente | Onde | Cluster |
|---|---|---|
| `dev` | Proxmox (home lab) | k3s: 1 control plane + 2 workers |
| `prod` | AWS us-east-1 | EKS com nós spot, criado e destruído a cada teste |

Decisões de arquitetura ficam em [`docs/adr/`](docs/adr/).

## Status

- [x] 0. Fundação: repositório, conta AWS com SSO e alerta de custo
- [ ] 1. Lab no Proxmox: Terraform + cloud-init, 3 VMs, k3s, state remoto **(em andamento)**
- [ ] 2. App + Helm
- [ ] 3. CI
- [ ] 4. CD (Argo CD)
- [ ] 5. Gateway (Traefik) + HPA
- [ ] 6. Escala por métricas (KEDA) + testes k6
- [ ] 7. AWS (EKS + Karpenter)
- [ ] 8. Hardening + vitrine

## Pré-requisitos numa máquina nova

O que é preciso para rodar o lab (`infra/proxmox`) a partir de um computador que nunca rodou o projeto.

### 1. Ferramentas

| Ferramenta | Versão | Para quê |
|---|---|---|
| `git` | qualquer recente | clonar o repositório |
| `terraform` | ≥ 1.17 | criar as VMs no Proxmox |
| `ssh` (OpenSSH) | qualquer recente | o Terraform envia os arquivos de cloud-init ao Proxmox por SSH |

Nas próximas fases entram `kubectl`, `helm`, `aws` (CLI v2) e `k6`.

### 2. No Proxmox (uma vez por servidor)

Isso não é feito pelo Terraform; precisa existir antes do primeiro `apply`.

1. **Template de VM:** cloud image do Debian 13 com `qemu-guest-agent` instalado, com VMID `9000` (ou ajuste `template_id`).
2. **Usuário da API:** usuário `terraform@pve`, com uma role com permissões de VM, storage e rede, e um **API token** para ele. O token só aparece uma vez, na criação: guarde num gerenciador de senhas.
3. **Storage de snippets:** no storage `local` (tipo diretório), habilite o conteúdo *Snippets* em `Datacenter > Storage > local > Edit > Content`. É onde o Terraform grava o cloud-init de cada VM.
4. **Chave SSH no root:** a chave pública da sua máquina precisa estar autorizada no root do Proxmox, porque o upload dos snippets é feito por SSH (a API não aceita esse upload):

   ```bash
   ssh-copy-id -i ~/.ssh/id_ed25519.pub root@<ip-do-proxmox>
   ```

   Pelo Shell da interface web, use `>>` (acrescentar) e nunca `>`: no Proxmox, `/root/.ssh/authorized_keys` aponta para o arquivo de chaves do cluster.

### 3. Arquivos que não estão no Git

O Terraform lê estes arquivos da sua máquina. Eles ficam fora do repositório por conterem segredos ou dados do seu lab.

| Arquivo | Conteúdo | Como obter |
|---|---|---|
| `~/.config/proxmox/terraform-token` | API token do Proxmox, numa linha: `terraform@pve!<id>=<secret>` | Do gerenciador de senhas. Se perdeu, crie outro token no Proxmox |
| `~/.ssh/id_ed25519` (e `.pub`) | Chave SSH aceita pelo root do Proxmox e colocada nas VMs | `ssh-keygen -t ed25519`, depois o passo 2.4 acima |
| `infra/proxmox/terraform.tfvars` | Endpoint da API, rede, IPs e tamanho das VMs | Copie de `terraform.tfvars.example` e ajuste |

Criando o arquivo do token:

```bash
mkdir -p ~/.config/proxmox
nano ~/.config/proxmox/terraform-token      # cole o token, numa linha só
chmod 600 ~/.config/proxmox/terraform-token
```

### 4. Subir o lab

```bash
git clone <url-do-repo> && cd <repo>/infra/proxmox
cp terraform.tfvars.example terraform.tfvars   # e ajuste os valores

ssh root@<ip-do-proxmox> true && echo "SSH ok"  # precisa entrar sem pedir senha

terraform init
terraform plan
terraform apply
```

Para conferir, entre numa VM com `ssh <usuario>@<ip-da-vm>`, usando o usuário definido em `user` e o IP definido em `vms`.

### Erros comuns

| Erro | Causa |
|---|---|
| `no file exists at ".../.config/proxmox/terraform-token"` | Falta o arquivo do token (passo 3) |
| `missing or empty value for the API endpoint` | Falta `proxmox_endpoint` no `terraform.tfvars` |
| Falha no upload do snippet / `Permission denied (publickey)` | A chave não está autorizada no root do Proxmox (passo 2.4) |
| Erro de conteúdo ao enviar o snippet | *Snippets* não habilitado no storage (passo 2.3) |

## O que nunca vai para o Git

Tokens, chaves privadas, `*.tfstate`, `terraform.tfvars`, kubeconfigs e `.env`. O `.gitignore` cobre esses arquivos; na AWS não há access keys: o acesso local é por SSO e o CI usa OIDC.

## Estrutura

```
infra/      Terraform: proxmox (dev), aws (prod), módulos
apps/       código da API
deploy/     Helm chart, plataforma (Traefik, KEDA, monitoring), Argo CD, values por ambiente
loadtest/   scripts k6
docs/       ADRs e imagens
```
