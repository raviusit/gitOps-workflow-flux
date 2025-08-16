# gitOps-workflow-flux

**Background -**
This repository contains my implementation of an SRE Challenge designed to demonstrate end-to-end skills in Kubernetes provisioning, 
GitOps workflows, application deployment, monitoring, and logging using Infrastructure as Code (IaC) principles.
The goal is to simulate a real-world Site Reliability Engineering scenario where an engineer is responsible for:
- Provisioning a secure and production-ready Kubernetes cluster using Terraform.
- Bootstrapping Flux for GitOps-based deployment automation.
- Deploying a sample web application with automated upgrades and rollbacks.
- Setting up basic monitoring (Prometheus, Grafana) and centralized logging (Fluentd).
- Following security, scalability, and resilience best practices.

This challenge emphasizes:
**Automation —** All components can be deployed or destroyed without manual intervention.
**Security-first design —** RBAC, Network Policies, and restricted Pod permissions.
**Operational excellence —** Observability and fault-tolerance are built in from the start.

The documentation in this repository captures the steps taken, the issues encountered, and the design choices made — making it reproducible and extensible for future improvements.

## 🏗️ Repository Structure
```
├── apps
│   └── staging
│       └── sre-challenge-app
│           ├── configmap.yaml
│           ├── deployment.yaml
│           ├── gitrepository.yaml
│           ├── health-monitor.yaml
│           ├── hpa.yaml
│           ├── imagepolicy.yaml
│           ├── imagerepository.yaml
│           ├── imageupdateautomation.yaml
│           ├── ingress.yaml
│           ├── kustomization-flux.yaml
│           ├── kustomization.yaml
│           ├── namespace.yaml              # App namespace
│           └── service.yaml
├── clusters
│   └── staging
│       ├── flux-system
│       │   ├── gotk-components.yaml        # Flux controllers
│       │   ├── gotk-sync.yaml              # Git repository sync
│       │   └── kustomization.yaml          # Flux system config
│       ├── image-automation.yaml
│       └── kustomization.yaml              # Cluster-level config
├── infrastructure
│   └── staging
│       ├── aws-load-balancer-controller
│       │   ├── crds.yaml
│       │   ├── deployment.yaml
│       │   ├── kustomization.yaml
│       │   ├── namespace.yaml
│       │   ├── rbac.yaml
│       │   ├── serviceaccount.yaml
│       │   └── webhook.yaml
│       ├── kustomization.yaml
│       └── monitoring
│           ├── application-health-dashboard.yaml
│           ├── fluent-bit.yaml
│           ├── kustomization.yaml
│           ├── namespace.yaml
│           ├── node-health-dashboard.yaml
│           ├── prometheus-operator.yaml
│           ├── servicemonitors.yaml
│           ├── simple-ingress.yaml
│           └── sre-challenge-dashboard.yaml
├── LICENSE
├── README.md
├── scripts
│   ├── deploy-global-regional.sh         # Terraform deployment script
│   └── install-flux.sh                   # Flux bootstrap script
└── terraform
    ├── environments
    │   ├── production
    │   │   ├── global
    │   │   │   └── terraform.tfvars
    │   │   └── regional
    │   │       ├── eu-central-1
    │   │       │   ├── main.tf
    │   │       │   ├── outputs.tf
    │   │       │   ├── terraform.tfvars
    │   │       │   └── variables.tf
    │   │       └── us-east-1
    │   │           ├── main.tf
    │   │           ├── outputs.tf
    │   │           ├── terraform.tfvars
    │   │           └── variables.tf
    │   └── staging
    │       ├── global
    │       │   ├── backend-config.hcl
    │       │   ├── backend.hcl
    │       │   ├── main.tf
    │       │   ├── outputs.tf
    │       │   ├── terraform.tfvars
    │       │   └── variables.tf
    │       └── regional
    │           ├── eu-central-1
    │           │   ├── backend-config.hcl
    │           │   ├── main.tf
    │           │   ├── outputs.tf
    │           │   ├── terraform.tfvars
    │           │   └── variables.tf
    │           └── us-east-1
    │               ├── main.tf
    │               ├── outputs.tf
    │               ├── terraform.tfvars
    │               └── variables.tf
    ├── modules
    │   ├── acm
    │   │   ├── main.tf
    │   │   ├── outputs.tf
    │   │   └── variables.tf
    │   ├── alb
    │   │   ├── main.tf
    │   │   ├── outputs.tf
    │   │   └── variables.tf
    │   ├── eks
    │   │   ├── main.tf
    │   │   ├── outputs.tf
    │   │   └── variables.tf
    │   ├── iam
    │   │   ├── main.tf
    │   │   ├── outputs.tf
    │   │   └── variables.tf
    │   ├── iam-basic
    │   │   ├── main.tf
    │   │   ├── outputs.tf
    │   │   └── variables.tf
    │   ├── iam-irsa
    │   │   ├── main.tf
    │   │   ├── outputs.tf
    │   │   └── variables.tf
    │   ├── route53
    │   │   ├── main.tf
    │   │   ├── outputs.tf
    │   │   └── variables.tf
    │   ├── route53-records
    │   │   ├── main.tf
    │   │   ├── outputs.tf
    │   │   └── variables.tf
    │   ├── s3
    │   │   ├── main.tf
    │   │   ├── outputs.tf
    │   │   └── variables.tf
    │   └── vpc
    │       ├── main.tf
    │       ├── outputs.tf
    │       └── variables.tf
    └── README.md

```


# 🚀 Phase 1: Infrastructure Setup

## What Has Been Created

### 🏗️ Terraform Modules
- **IAM Module**: EKS cluster roles, node group roles, AWS Load Balancer Controller, and Flux controller roles
- **VPC Module**: Multi-AZ VPC with public/private/database subnets, NAT gateways, security groups
- **EKS Module**: Managed Kubernetes cluster with node groups, addons, and OIDC provider
- **ALB Module**: Application Load Balancer with security groups and target groups
- **Route53 Module**: DNS management and SSL certificates via ACM
- **S3 Module**: Buckets for artifacts and configurations with lifecycle policies
- **ACM Module**: Automatic certificate management via ACM 


### 🌍 Multi-Region, Multi-Environment Structure
```
Staging Account (215876814712):
├── us-east-1    (VPC: 10.0.0.0/16)
└── eu-central-1 (VPC: 10.0.0.0/16)

Production Account (746848447423):
├── us-east-1    (VPC: 10.10.0.0/16)
└── eu-central-1 (VPC: 10.20.0.0/16)
```

### 🔒 Security Features Implemented
- **Network Isolation**: Private subnets for EKS nodes, security groups with minimal access
- **RBAC**: Kubernetes role-based access control enabled
- **Encryption**: KMS keys for EKS secrets and S3 buckets
- **IAM**: Least privilege roles with OIDC integration
- **Monitoring**: CloudWatch logging and VPC flow logs

## Quick Start Deployment

### Prerequisites
1. AWS CLI configured with profiles:
   ```bash
   aws configure --profile staging    # Account: 215876814712
   aws configure --profile production # Account: 746848447423
   ```

2. Terraform >= 1.0 installed
3. kubectl installed

### Step 1: Deploy Infrastructure
```bash
# Deploy staging infrastructure
./scripts/deploy-global-regional.sh staging eu-central-1 apply # this is the operational region for this POC
./scripts/deploy-global-regional.sh staging us-east-1 apply # Nearly equivalent but not tested

# Deploy production infrastructure
./scripts/deploy-global-regional.sh production us-east-1 apply # Nearly equivalent but not tested
./scripts/deploy-global-regional.sh production eu-central-1 apply # Nearly equivalent but not tested
```

### Step 2: Configure kubectl
```bash
# Connect to staging cluster
aws eks update-kubeconfig --region us-east-1 --name sre-challenge-staging --profile staging

# Verify connection
kubectl cluster-info
kubectl get nodes
```

## Environment Configurations

### Staging Environment
- **Deletion Protection**: Disabled (easy cleanup)
- **Log Retention**: 7 days
- **Node Groups**: Includes spot instances for cost optimization
- **Force Destroy**: Enabled for development workflows
- **Domain**: sre-challenge-panther.network

### Production Environment
- **TODO**

## Architecture Overview

### Network Design
- **3-Tier Architecture**: Public, Private, Database subnets
- **Multi-AZ**: Resources distributed across 3 availability zones
- **NAT Gateways**: High availability internet access for private subnets
- **Security Groups**: Minimal required access patterns

### EKS Configuration
- **Managed Node Groups**: Auto-scaling with desired/min/max capacity
- **Add-ons**: CoreDNS, kube-proxy, VPC-CNI, EBS CSI driver
- **Logging**: All control plane logs enabled
- **OIDC**: Service account integration ready

### Load Balancing
- **Application Load Balancer**: Layer 7 load balancing
- **Target Groups**: Health check configuration
- **SSL/TLS**: Automatic certificate management via ACM

## Validation Checklist

After deployment, verify:

```bash
# ✅ EKS Cluster Status
aws eks describe-cluster --name sre-challenge-staging --region us-east-1 --profile staging

# ✅ Node Groups
kubectl get nodes -o wide

# ✅ Cluster Services
kubectl get pods -n kube-system

# ✅ Load Balancer
aws elbv2 describe-load-balancers --region us-east-1 --profile staging

# ✅ Route53 Records
aws route53 list-hosted-zones --profile staging

# ✅ S3 Buckets
aws s3 ls --profile staging
```


# 🚀 Phase 2: Flux GitOps Setup

## 📋 Overview

- **Repository Structure**: GitOps-ready with staging/production separation
- **Application**: nginx web server with health checks and auto-scaling
- **Monitoring**: Built-in health checks, HPA, and rollback capabilities
- **Security**: RBAC-enabled, namespace isolation, resource limits

## 🎯 Installation Steps

### 1. Prerequisites

Ensure you have:
- ✅ EKS cluster running (from Phase 1)
- ✅ kubectl configured and working
- ✅ Flux CLI installed
- ✅ GitHub Personal Access Token with repo permissions

#### Install Flux CLI
```bash
brew install fluxcd/tap/flux
```

#### Create GitHub Token
1. Go to GitHub Settings > Developer settings > Personal access tokens
2. Create token with `repo` permissions
3. Export it: `export GITHUB_TOKEN=<your-token>`

### 2. Bootstrap Flux

Run the installation script:

```bash
./scripts/install-flux.sh <your-github-username> staging
```

This will:
- Install Flux controllers in `flux-system` namespace
- Configure GitRepository pointing to your repo
- Setup Kustomization to sync `clusters/staging`
- Commit Flux manifests to your repository

### 3. Verify Installation

```bash
# Check Flux status
flux get sources git
flux get kustomizations

# Check application deployment
kubectl get pods -n sre-challenge
kubectl get ingress -n sre-challenge
kubectl get hpa -n sre-challenge
```

## 🔧 Application Features

### Health Checks
- **Liveness Probe**: HTTP GET on `/` every 10s
- **Readiness Probe**: HTTP GET on `/` every 5s  
- **Health Endpoint**: `/health` returns "healthy" status
- **Ingress Health**: ALB health checks on `/health` every 15s

### Auto-scaling
- **Min Replicas**: 2 (High Availability)
- **Max Replicas**: 10 (Burst capacity)
- **CPU Target**: 70% utilization
- **Memory Target**: 80% utilization
- **Scale-down**: 50% reduction every 60s (5min stabilization)
- **Scale-up**: 100% increase every 15s (1min stabilization)

### Security & Resource Management
- **Namespace Isolation**: `sre-challenge` namespace
- **Resource Requests**: 50m CPU, 64Mi memory
- **Resource Limits**: 100m CPU, 128Mi memory
- **RBAC**: Minimal required permissions
- **Image**: nginx:1.25-alpine (security-focused)

## 🎨 Application Details

The sample application includes:
- **Modern UI**: Responsive design with glassmorphism effects
- **Environment Info**: Shows staging environment details
- **Health Status**: Visual confirmation of successful deployment
- **Version Tracking**: Displays deployment timestamp
- **Performance**: Optimized nginx configuration with gzip

## 🔄 GitOps Workflow

### Making Changes
1. **Edit manifests** in `apps/staging/sre-challenge-app/`
2. **Commit & push** changes to repository
3. **Flux automatically syncs** within 1 minute
4. **Monitor deployment**: `flux get kustomizations --watch`

### Version Updates
Update the image tag in `deployment.yaml`:
```yaml
containers:
- name: nginx
  image: nginx:1.26-alpine  # Updated version
```

### Configuration Changes
Modify `configmap.yaml` to update:
- nginx configuration
- HTML content
- Application settings

## 🚨 Automated Rollbacks

Flux provides automatic rollback capabilities:

### Health Check Failures
If pods fail health checks:
- **Readiness failures**: Traffic stops routing to failed pods
- **Liveness failures**: Kubernetes restarts failed pods
- **Multiple failures**: HPA may scale up additional replicas

### Deployment Failures
If deployment fails to roll out:
- **Flux reconciliation**: Continuously attempts to achieve desired state
- **Manual rollback**: `kubectl rollout undo deployment/sre-challenge-app -n sre-challenge`
- **Git revert**: Revert commit in Git repository for automatic rollback

### Configuration for Auto-rollback
Add to `deployment.yaml` spec:
```yaml
spec:
  progressDeadlineSeconds: 300
  revisionHistoryLimit: 5
  strategy:
    rollingUpdate:
      maxSurge: 50%
      maxUnavailable: 25%
```

## 📊 Monitoring Commands

```bash
# Application Status
kubectl get pods -n sre-challenge
kubectl describe deployment sre-challenge-app -n sre-challenge
kubectl get hpa -n sre-challenge

# Flux Status
flux get kustomizations
flux get sources git
flux logs --follow

# Application Logs  
kubectl logs -l app=sre-challenge-app -n sre-challenge

# Ingress Status
kubectl get ingress -n sre-challenge
kubectl describe ingress sre-challenge-app -n sre-challenge
```

## 🌐 Accessing the Application

Once deployed, the application will be available at:
- **URL**: `http://eu-central-1.sre-challenge-staging.local`
- **Health Check**: `http://eu-central-1.sre-challenge-staging.local/health`

> **Note**: You may need to add the ALB DNS name to your hosts file or use the actual ALB endpoint.

## 🔧 Troubleshooting

### Common Issues

**1. Flux not syncing**
```bash
flux reconcile source git flux-system
flux reconcile kustomization flux-system
```

**2. Application not deploying**
```bash
kubectl describe kustomization flux-system -n flux-system
kubectl get events -n sre-challenge
```

**3. Ingress not working**
```bash
kubectl get ingress -n sre-challenge
kubectl describe ingress sre-challenge-app -n sre-challenge
```

**4. Pods not starting**
```bash
kubectl describe pod -l app=sre-challenge-app -n sre-challenge
kubectl logs -l app=sre-challenge-app -n sre-challenge
```

### Debug Commands
```bash
# Full Flux status
flux check
flux get all

# Application debugging
kubectl get all -n sre-challenge
kubectl describe deployment sre-challenge-app -n sre-challenge
```

## 🎯 Success Criteria

✅ **Flux Installation**: Controllers running in flux-system namespace  
✅ **Git Synchronization**: Repository syncing every minute  
✅ **Application Deployment**: Pods running in sre-challenge namespace  
✅ **Health Checks**: All probes passing  
✅ **Auto-scaling**: HPA configured and responsive  
✅ **Ingress**: ALB created and routing traffic  
✅ **Rollback Capability**: Deployment history maintained  

## 🚀 Next Steps

After successful Phase 2 completion:
1. **Phase 3**: Application Deployment - Deploy different app versions
2. **Phase 4**: Monitoring and Logging - Setup Prometheus & Grafana  
3. **Phase 5**: Documentation - Complete setup documentation

---

**SRE Challenge - Phase 2 Complete! 🎉**