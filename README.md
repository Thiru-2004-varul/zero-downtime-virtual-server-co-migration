# Zero Downtime Virtual Server Co-Migration

![CI/CD](https://github.com/Thiru-2004-varul/zero-downtime-virtual-server-co-migration/actions/workflows/deploy.yml/badge.svg)

## The Problem

Every company that runs a mobile app faces this question:
**"How do we update our app without users noticing?"**

The traditional answer — shut everything down, update, restart — causes downtime.
This project proves there is a better way, and measures the exact difference.

---

## The Proof

| What we measured | Rolling Update | Recreate |
|---|---|---|
| Downtime | **0 seconds** | **8 seconds** |
| Mobile users affected | None | Service unavailable |
| Pod replacement | One at a time | All at once |
| Safe for production | Yes | No |

Real terminal output saved in `results/` — not made up numbers.

---

## How it works

A Tic Tac Toe game runs as v1 (blue). We migrate it to v2 (green) using two strategies.

**Rolling Update — what actually happens:**
```
08:45:46  {"status":"ok","version":"v1"}   ← still on v1
08:45:47  {"status":"ok","version":"v2"}   ← v2 pod started, v1 still running
08:45:48  {"status":"ok","version":"v1"}   ← both pods serving traffic
08:45:50  {"status":"ok","version":"v2"}   ← v1 pod terminated, fully on v2
```
Zero gaps. Zero errors. Users never noticed.

**Recreate — what actually happens:**
```
08:52:31  {"status":"ok","version":"v1"}   ← last v1 response
08:52:35   ---                             ← BLANK — all pods killed
08:52:36   ---                             ← connection refused
08:52:37   ---                             ← connection refused
08:52:38   ---                             ← connection refused
08:52:43  {"status":"ok","version":"v2"}   ← new pods finally ready
```
8 seconds of complete unavailability. Every user got a blank page.

---

## Why Rolling Update works — the key YAML
```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 0   # NEVER kill old pod before new pod is ready
    maxSurge: 1         # start 1 EXTRA pod during update (3 pods briefly)
```

The Kubernetes Service only sends traffic to pods that pass the readiness probe.
The new pod must prove it is healthy BEFORE the old pod is terminated.
That is why there is never a gap.

**Recreate has none of this protection:**
```yaml
strategy:
  type: Recreate   # kills ALL pods first — no protection
```

---

## What I built — full stack
```
Your laptop
    │
    │  git push
    ▼
GitHub Actions CI/CD
    │  test → build → scan → validate → terraform plan
    ▼
Docker Hub
    │  thiru2004/mobile-app:v1 and v2
    ▼
AWS Infrastructure (Terraform)
    │
    ├── VPC 10.0.0.0/16 (Mumbai ap-south-1)
    │   ├── AZ ap-south-1a
    │   │   ├── Public subnet  → Bastion host, NAT Gateway
    │   │   └── Private subnet → K8s Master EC2
    │   │                        API server, etcd, scheduler
    │   └── AZ ap-south-1b
    │       ├── Public subnet  → ALB endpoint
    │       └── Private subnet → K8s Worker EC2
    │                            kubelet, containerd, your pods
    │
    └── ALB (port 80) → Worker NodePort (30007) → Pod (5000)
```

Master and worker in separate AZs — if one data center fails, the other keeps running.

---

## Tech Stack

| Tool | What it does in this project |
|---|---|
| Python Flask | Tic Tac Toe app — v1 blue, v2 green with scoreboard |
| Docker | Packages app into container image |
| Kubernetes | Runs and manages pods — Rolling Update and Recreate |
| Minikube | Local Kubernetes cluster for testing |
| Terraform | Creates all AWS infrastructure automatically |
| AWS EC2 | Runs Kubernetes master and worker nodes |
| AWS ALB | Receives HTTP traffic, distributes to K8s nodes |
| AWS VPC | Isolated private network across 2 Availability Zones |
| Bastion Host | SSH jump server — only entry point to private nodes |
| NAT Gateway | Lets private nodes pull Docker images without public IP |
| Prometheus | Scrapes /metrics every 15s — tracks app_up metric |
| Grafana | Graphs app_up — shows the 8 second dip during Recreate |
| GitHub Actions | Auto tests, builds, scans on every git push |

---

## Infrastructure — how Terraform builds it

Two scripts run automatically when EC2 instances boot:

**scripts/master-init.sh** — turns a blank Ubuntu EC2 into a Kubernetes master:
- Installs containerd (container runtime)
- Installs kubelet, kubeadm, kubectl
- Disables swap (Kubernetes requirement)
- Runs `kubeadm init` — creates the cluster
- Installs Calico CNI — gives pods IP addresses
- Saves the worker join command

**scripts/worker-init.sh** — turns a blank Ubuntu EC2 into a Kubernetes worker:
- Same setup as master minus `kubeadm init`
- Waits for you to run the join command
- Once joined: kubelet starts, containerd starts, ready for pods

No manual setup. Terraform boots the EC2, script runs automatically.

---

## CI/CD Pipeline — what happens on every git push
```
git push to main
      │
      ├── detect-changes   which files changed? v1 / v2 / k8s
      │
      ├── test-v1          start Flask app, hit /health — pass or fail
      ├── test-v2          start Flask app, hit /health — pass or fail
      │
      ├── build-v1         docker build + push thiru2004/mobile-app:v1
      ├── build-v2         docker build + push thiru2004/mobile-app:v2
      │
      ├── security         Trivy scans image for HIGH/CRITICAL vulnerabilities
      ├── validate-k8s     kubectl dry-run — checks YAML without a real cluster
      ├── terraform-plan   shows what AWS changes would happen — never applies
      │
      └── notify           prints every job result — always runs
```

Tests only run for files that actually changed — saves time.
Docker images only push on main branch — not on pull requests.

---

## Monitoring — how the graph proves downtime
```
app_up metric over time:

Rolling Update:
1 ─────────────────────────────────────────── (never drops)

Recreate:
1 ──────────────┐         ┌──────────────────
                │         │
0               └─────────┘
                  8 seconds
```

Prometheus scrapes `/metrics` every 15 seconds and records:
- `app_up` — 1 if app is running, 0 if down
- `app_requests_total` — total requests served since start
- `app_uptime_seconds` — how long the app has been running

---

## Run it yourself — local
```bash
# Start minikube
minikube start --driver=docker --cpus=2 --memory=3000

# Deploy both strategies
kubectl apply -f k8s/rolling-deployment.yml
kubectl apply -f k8s/service.yml
kubectl apply -f k8s/recreate-deployment.yml
kubectl apply -f k8s/recreate-service.yml
kubectl apply -f k8s/monitoring.yml

# Get URLs
minikube service mobile-app-service --url
minikube service mobile-app-recreate-service --url
```

**Test Rolling Update:**
```bash
# Terminal 1 — watch the app
URL=$(minikube service mobile-app-service --url)
while true; do
  curl -s --max-time 2 $URL/health
  echo " --- $(date +%T)"
  sleep 1
done

# Terminal 2 — trigger migration
kubectl set image deployment/mobile-app mobile-app=thiru2004/mobile-app:v2
```

**Test Recreate:**
```bash
# Terminal 1 — watch the app
URL=$(minikube service mobile-app-recreate-service --url)
while true; do
  curl -s --max-time 2 $URL/health 2>&1
  echo " --- $(date +%T)"
  sleep 1
done

# Terminal 2 — trigger migration
kubectl set image deployment/mobile-app-recreate mobile-app=thiru2004/mobile-app:v2
```

---

## Run it on AWS
```bash
cd terraform

# Preview what will be created
terraform plan -var="key_name=your-key-name"

# Create everything (VPC, subnets, EC2, ALB, NAT, Bastion)
terraform apply -var="key_name=your-key-name"

# After apply — Terraform prints:
# alb_dns_name            → paste in browser to reach app
# bastion_public_ip       → your SSH entry point
# private_ec2_private_ips → master and worker IPs
```

**SSH into cluster:**
```bash
# Into bastion
ssh -i your-key.pem ubuntu@BASTION_PUBLIC_IP

# Into master (from bastion)
ssh -i your-key.pem ubuntu@MASTER_PRIVATE_IP

# Into worker (from bastion) — run join command
ssh -i your-key.pem ubuntu@WORKER_PRIVATE_IP
sudo bash /home/ubuntu/join-command.sh

# Check cluster
kubectl get nodes
```

**Destroy when done (save AWS costs):**
```bash
terraform destroy -var="key_name=your-key-name"
```

---

## Proof Files

`results/rolling-update-output.txt` — real curl output during Rolling Update.
Every line has a response. Zero gaps. v1 quietly becomes v2.

`results/recreate-output.txt` — real curl output during Recreate.
Lines go blank from 08:52:35 to 08:52:43. 8 seconds of nothing.

---

## Docker Images
```
thiru2004/mobile-app:v1      # blue theme — basic game
thiru2004/mobile-app:v2      # green theme — scoreboard added
thiru2004/mobile-app:latest  # always newest
```

---

## Author

**Thiruvarul G** - 
GitHub: [@Thiru-2004-varul](https://github.com/Thiru-2004-varul)
