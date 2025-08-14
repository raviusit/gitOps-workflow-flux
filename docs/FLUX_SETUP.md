# 🚀 Phase 2: Flux GitOps Setup

This document outlines the setup and configuration of Flux for GitOps workflow on the SRE Challenge EKS cluster.

## 📋 Overview

- **Repository Structure**: GitOps-ready with staging/production separation
- **Application**: nginx web server with health checks and auto-scaling
- **Monitoring**: Built-in health checks, HPA, and rollback capabilities
- **Security**: RBAC-enabled, namespace isolation, resource limits

## 🏗️ Repository Structure

```
gitOps-workflow-flux/
├── clusters/
│   └── staging/
│       ├── flux-system/
│       │   ├── gotk-components.yaml    # Flux controllers
│       │   ├── gotk-sync.yaml          # Git repository sync
│       │   └── kustomization.yaml     # Flux system config
│       └── kustomization.yaml         # Cluster-level config
├── apps/
│   └── staging/
│       └── sre-challenge-app/
│           ├── namespace.yaml          # App namespace
│           ├── deployment.yaml         # App deployment
│           ├── service.yaml            # ClusterIP service
│           ├── configmap.yaml          # nginx config + content
│           ├── ingress.yaml            # ALB ingress
│           ├── hpa.yaml                # Horizontal Pod Autoscaler
│           └── kustomization.yaml     # App-level config
├── infrastructure/
│   └── staging/
│       └── monitoring/
│           └── namespace.yaml          # Monitoring namespace
└── scripts/
    └── install-flux.sh                # Flux bootstrap script
```

## 🎯 Installation Steps

### 1. Prerequisites

Ensure you have:
- ✅ EKS cluster running (from Phase 1)
- ✅ kubectl configured and working
- ✅ Flux CLI installed
- ✅ GitHub Personal Access Token with repo permissions

#### Install Flux CLI
```bash
# macOS
brew install fluxcd/tap/flux

# Linux
curl -s https://fluxcd.io/install.sh | sudo bash
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