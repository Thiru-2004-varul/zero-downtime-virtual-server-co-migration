# Zero Downtime Virtual Server Co-Migration
## Online vs Offline Migration for Mobile Access

![CI/CD](https://github.com/Thiru-2004-varul/zero-downtime-virtual-server-co-migration/actions/workflows/deploy.yml/badge.svg)

## Project Overview

This project demonstrates virtual server co-migration for mobile access by comparing two Kubernetes deployment strategies:

- **Online Migration** (Rolling Update) → zero downtime, mobile users unaffected
- **Offline Migration** (Recreate) → causes downtime, mobile users experience interruption

## Architecture
```
Internet
    │
    ▼
[ALB / Minikube NodePort]
    │
    ▼
[Kubernetes Cluster]
    ├── Pod (mobile-app:v1) ──► Online Migration ──► Pod (mobile-app:v2)
    └── Pod (mobile-app:v1) ──► Offline Migration ──► Pod (mobile-app:v2)
    │
    ▼
[Prometheus + Grafana Monitoring]
```

## Tech Stack

| Tool | Purpose |
|---|---|
| Python Flask | Web application (Tic Tac Toe game) |
| Docker | Containerize the application |
| Kubernetes | Orchestrate and manage pods |
| Terraform | AWS infrastructure as code |
| Prometheus | Collect app metrics |
| Grafana | Visualize metrics and downtime |
| GitHub Actions | CI/CD pipeline automation |

## Project Structure
```
zero-downtime-virtual-server-co-migration/
├── app/
│   ├── v1/                          # Basic Tic Tac Toe (blue theme)
│   │   ├── app.py
│   │   ├── Dockerfile
│   │   └── requirements.txt
│   └── v2/                          # Pro Tic Tac Toe with scoreboard (green theme)
│       ├── app.py
│       ├── Dockerfile
│       └── requirements.txt
├── k8s/
│   ├── rolling-deployment.yml       # Online migration strategy
│   ├── recreate-deployment.yml      # Offline migration strategy
│   ├── service.yml                  # Service for rolling deployment
│   ├── recreate-service.yml         # Service for recreate deployment
│   └── monitoring.yml               # Prometheus + Grafana
├── terraform/                       # AWS infrastructure
│   ├── vpc.tf
│   ├── subnets.tf
│   ├── ec2.tf
│   ├── alb.tf
│   ├── security_groups.tf
│   ├── bastion.tf
│   ├── igw.tf
│   ├── nat.tf
│   ├── routes.tf
│   ├── outputs.tf
│   ├── variables.tf
│   └── provider.tf
├── scripts/
│   ├── master-init.sh               # K8s master node setup
│   └── worker-init.sh               # K8s worker node setup
└── .github/
    └── workflows/
        └── deploy.yml               # CI/CD pipeline
```

## Application Versions

| Version | Theme | Features |
|---|---|---|
| v1 | Blue | Basic Tic Tac Toe game |
| v2 | Green | Tic Tac Toe + scoreboard + migration note |

## Migration Strategies

### Online Migration — Rolling Update
```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 0
    maxSurge: 1
```
- New pod starts before old pod dies
- Always at least 2 pods running
- Zero downtime proven by continuous curl responses

### Offline Migration — Recreate
```yaml
strategy:
  type: Recreate
```
- All old pods killed first
- Gap with zero pods running
- Downtime of ~18 seconds proven by curl timeouts

## CI/CD Pipeline

Every git push triggers:
```
detect-changes → test-v1 → build-v1
              → test-v2 → build-v2 → security-scan
              → validate-k8s
              → terraform-plan
              → notify
```

- Tests run only for changed version
- Docker images pushed to Docker Hub with version tags
- K8s manifests validated with dry-run
- Terraform plan shows AWS infrastructure changes
- Security scan with Trivy

## Monitoring

- Prometheus scrapes `/metrics` endpoint every 15 seconds
- Grafana visualizes:
  - `app_up` — proves downtime during Recreate strategy
  - `app_requests_total` — total requests served
  - `app_uptime_seconds` — how long app has been running

## Local Setup

### Prerequisites
```bash
minikube
kubectl
docker
```

### Run Locally
```bash
# Start minikube
minikube start --driver=docker --cpus=2 --memory=3000

# Deploy app
kubectl apply -f k8s/rolling-deployment.yml
kubectl apply -f k8s/service.yml

# Get URL
minikube service mobile-app-service --url

# Deploy monitoring
kubectl apply -f k8s/monitoring.yml
```

### Test Online Migration (Zero Downtime)
```bash
# Terminal 1 - keep hitting app
URL=$(minikube service mobile-app-service --url)
while true; do
  curl -s $URL/health
  echo " --- $(date +%T)"
  sleep 1
done

# Terminal 2 - trigger migration
kubectl set image deployment/mobile-app \
  mobile-app=thiru2004/mobile-app:v2
```

### Test Offline Migration (Downtime)
```bash
# Deploy recreate strategy
kubectl apply -f k8s/recreate-deployment.yml
kubectl apply -f k8s/recreate-service.yml

# Terminal 1 - keep hitting app
URL2=$(minikube service mobile-app-recreate-service --url)
while true; do
  curl -s --max-time 2 $URL2/health 2>&1
  echo " --- $(date +%T)"
  sleep 1
done

# Terminal 2 - trigger migration
kubectl set image deployment/mobile-app-recreate \
  mobile-app=thiru2004/mobile-app:v2
```

## AWS Infrastructure (Terraform)
```
VPC (10.0.0.0/16)
├── Public Subnets  → ALB, Bastion
└── Private Subnets → K8s Master, K8s Workers

terraform plan -var="key_name=your-key"
```

## Results

| Metric | Rolling Update | Recreate |
|---|---|---|
| Downtime | 0 seconds | ~18 seconds |
| Mobile Impact | None | Service unavailable |
| Pod replacement | Gradual | All at once |
| Risk | Low | Higher |
| Use case | Production | Dev/Test |

## Docker Images
```
thiru2004/mobile-app:v1      - stable v1
thiru2004/mobile-app:v2      - stable v2
thiru2004/mobile-app:latest  - always latest
```

## Author

**Thiruvarul G**
- GitHub: [@Thiru-2004-varul](https://github.com/Thiru-2004-varul)
