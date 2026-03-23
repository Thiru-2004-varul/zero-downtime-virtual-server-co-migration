# Zero Downtime Virtual Server Co-Migration

![EKS Pipeline](https://github.com/Thiru-2004-varul/zero-downtime-virtual-server-co-migration/actions/workflows/eks-deploy.yml/badge.svg)

## What This Project Proves

Every company running a mobile app faces this question:
**"How do we update our app without users noticing?"**

This project answers it with real evidence — not theory.

| What we measured | Result |
|---|---|
| Downtime during migration | **0 seconds** |
| Mobile users affected | **None** |
| Strategy used | **Kubernetes Rolling Update** |
| Proof | Real terminal output in `results/` |

---
 
## How It Works

A Python Flask Tic Tac Toe game runs as **v1** (blue theme).
We migrate it live to **v2** (green theme + scoreboard) using
Kubernetes Rolling Update on Amazon EKS.

**What the terminal shows during migration:**
```
08:45:46  {"status":"ok","version":"v1"}   ← still on v1
08:45:47  {"status":"ok","version":"v2"}   ← v2 pod started, v1 still running
08:45:48  {"status":"ok","version":"v1"}   ← both pods serving traffic
08:45:50  {"status":"ok","version":"v2"}   ← fully migrated, v1 removed
```
Zero gaps. Zero errors. Users never noticed.

**Why it works — the key YAML:**
```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 0   # never kill old pod before new pod is ready
    maxSurge: 1         # start 1 extra pod during update
```

The new pod must pass the `/health` readiness probe before
the old pod is removed. That is why there is never a gap.

---

## Architecture
```
Your laptop
    │
    │  git push
    ▼
GitHub Actions (OIDC — no AWS keys stored)
    │  test → scan → build → push to ECR → terraform plan
    ▼
Amazon ECR
    │  697551514015.dkr.ecr.ap-south-1.amazonaws.com/mobile-app
    ▼
AWS Infrastructure (Terraform — ap-south-1 Mumbai)
    │
    ├── VPC 10.0.0.0/16
    │   ├── AZ ap-south-1a
    │   │   ├── Public subnet  → NAT Gateway
    │   │   └── Private subnet → EKS Node
    │   └── AZ ap-south-1b
    │       ├── Public subnet  → NAT Gateway
    │       └── Private subnet → EKS Node
    │
    └── EKS Managed Cluster (vmcm-eks)
        ├── Control plane — managed by AWS
        ├── Node group — 2 x t3.medium across 2 AZs
        ├── OIDC provider — IRSA token auth for pods
        └── NLB — auto-provisioned by K8s LoadBalancer service
```

---

## Tech Stack

| Tool | Role |
|---|---|
| Python Flask | App — v1 blue, v2 green + scoreboard |
| Docker | Packages app into container images |
| Amazon EKS | Managed Kubernetes — no kubeadm needed |
| Amazon ECR | Private container registry — scanned on push |
| Kubernetes Rolling Update | Zero downtime migration strategy |
| Terraform | Provisions all AWS infrastructure as code |
| AWS VPC | Isolated private network across 2 AZs |
| NAT Gateway | Private nodes pull images without public IP |
| SSM Session Manager | Node access — no port 22, any WiFi |
| OIDC + IRSA | Token-based auth — no AWS keys anywhere |
| Prometheus + Grafana | Live metrics — proves 0 sec downtime |
| GitHub Actions | CI/CD — test, scan, build, push on every push |

---

## Prerequisites
```bash
# AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip
unzip awscliv2.zip && sudo ./aws/install

# kubectl
curl -LO "https://dl.k8s.io/release/v1.29.0/bin/linux/amd64/kubectl"
chmod +x kubectl && sudo mv kubectl /usr/local/bin/

# SSM Session Manager plugin
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" \
  -o ssm-plugin.deb
sudo dpkg -i ssm-plugin.deb

# Terraform
wget https://releases.hashicorp.com/terraform/1.7.0/terraform_1.7.0_linux_amd64.zip
unzip terraform_1.7.0_linux_amd64.zip && sudo mv terraform /usr/local/bin/
```

---

## Deploy — Step by Step

### 1. Configure AWS credentials
```bash
aws configure
# AWS Access Key ID     : your key
# AWS Secret Access Key : your secret
# Default region        : ap-south-1
# Default output format : json
```

### 2. Terraform plan and apply
```bash
cd terraform
terraform init
terraform plan -var="key_name=vmcm-key"
terraform apply -var="key_name=vmcm-key"
```

Outputs after apply:
```
eks_cluster_name         = "vmcm-eks"
ecr_repository_url       = "697551514015.dkr.ecr.ap-south-1.amazonaws.com/mobile-app"
github_actions_role_arn  = "arn:aws:iam::697551514015:role/vmcm-eks-github-actions-role"
mobile_app_irsa_role_arn = "arn:aws:iam::697551514015:role/vmcm-eks-mobile-app-irsa"
kubeconfig_command       = "aws eks update-kubeconfig --region ap-south-1 --name vmcm-eks"
```

### 3. Configure kubectl
```bash
aws eks update-kubeconfig --region ap-south-1 --name vmcm-eks
kubectl get nodes
# NAME                STATUS   ROLES    AGE
# ip-10-0-x-x...     Ready    <none>   2m
# ip-10-0-x-x...     Ready    <none>   2m
```

### 4. Push images to ECR
```bash
aws ecr get-login-password --region ap-south-1 | \
  docker login --username AWS --password-stdin \
  697551514015.dkr.ecr.ap-south-1.amazonaws.com

docker build -t 697551514015.dkr.ecr.ap-south-1.amazonaws.com/mobile-app:v1 app/v1/
docker push 697551514015.dkr.ecr.ap-south-1.amazonaws.com/mobile-app:v1

docker build -t 697551514015.dkr.ecr.ap-south-1.amazonaws.com/mobile-app:v2 app/v2/
docker push 697551514015.dkr.ecr.ap-south-1.amazonaws.com/mobile-app:v2
```

### 5. Deploy to EKS
```bash
kubectl apply -f k8s/serviceaccount.yml
kubectl apply -f k8s/eks-deployment.yml
kubectl apply -f k8s/eks-service.yml
kubectl apply -f k8s/monitoring.yml

kubectl get pods -w
kubectl get svc mobile-app-eks-service
```

### 6. Test zero downtime migration
```bash
# Terminal 1 — watch the app continuously
URL=$(kubectl get svc mobile-app-eks-service \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

while true; do
  curl -s --max-time 2 http://$URL/health
  echo " --- $(date +%T)"
  sleep 1
done

# Terminal 2 — trigger migration from v1 to v2
kubectl set image deployment/mobile-app \
  mobile-app=697551514015.dkr.ecr.ap-south-1.amazonaws.com/mobile-app:v2
```

Terminal 1 will show continuous responses with zero gaps.

---

## Connect to EKS Nodes

No port 22. No Bastion. Works on any WiFi.
```bash
# Get node instance IDs
aws ec2 describe-instances \
  --filters "Name=tag:eks:cluster-name,Values=vmcm-eks" \
  --query "Reservations[].Instances[].InstanceId" \
  --output text \
  --region ap-south-1

# Connect via SSM
aws ssm start-session --target INSTANCE_ID --region ap-south-1

# Or: AWS Console → EC2 → select node → Connect → Session Manager
```

---

## CI/CD Pipeline

Every `git push` to main triggers:

| Job | What it does |
|---|---|
| `detect-changes` | Checks which files changed |
| `test` | Starts Flask app, hits `/health` endpoint |
| `security-scan` | Trivy scans image for HIGH/CRITICAL CVEs |
| `build-push-ecr` | Builds images, pushes to ECR + Docker Hub via OIDC |
| `terraform-plan` | Shows infrastructure changes — never applies |
| `validate-k8s` | kubectl dry-run on all manifests |
| `notify` | Prints summary of all jobs |

**No AWS access keys stored in GitHub.**
GitHub Actions uses OIDC to get a short-lived token automatically.

GitHub Secrets required:

| Secret | Value |
|---|---|
| `DOCKER_USERNAME` | `thiru2004` |
| `DOCKER_PASSWORD` | your Docker Hub token |
| `AWS_KEY_NAME` | `vmcm-key` |

---

## Monitoring
```bash
# Get Grafana URL
kubectl get svc grafana-service -n monitoring

# Open in browser — NodePort 30030
# Login: admin / admin123
```

Grafana shows `app_up` metric over time.
During Rolling Update: flat line at 1 — never drops.

---

## Destroy When Done
```bash
# Delete K8s resources first — removes NLB from AWS
kubectl delete -f k8s/eks-service.yml
kubectl delete -f k8s/eks-deployment.yml
kubectl delete -f k8s/serviceaccount.yml
kubectl delete -f k8s/monitoring.yml

# Destroy all AWS infrastructure
cd terraform
terraform destroy -var="key_name=vmcm-key"
```

---

## Proof Files

| File | What it shows |
|---|---|
| `results/rolling-update-output.txt` | Every curl response during migration — zero gaps |
| `results/recreate-output.txt` | 8 second blank window — kept as comparison evidence |

---

## Author

**Thiruvarul G**
GitHub: [@Thiru-2004-varul](https://github.com/Thiru-2004-varul)