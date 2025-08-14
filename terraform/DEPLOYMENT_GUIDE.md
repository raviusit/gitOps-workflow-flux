# Phase 1: Infrastructure Deployment Guide

## What Has Been Created

### 🏗️ Terraform Modules
- **IAM Module**: EKS cluster roles, node group roles, AWS Load Balancer Controller, and Flux controller roles
- **VPC Module**: Multi-AZ VPC with public/private/database subnets, NAT gateways, security groups
- **EKS Module**: Managed Kubernetes cluster with node groups, addons, and OIDC provider
- **ALB Module**: Application Load Balancer with security groups and target groups
- **Route53 Module**: DNS management and SSL certificates via ACM
- **S3 Module**: Buckets for artifacts and configurations with lifecycle policies

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

### Step 1: Create Backend Infrastructure
```bash
# Create backend for staging us-east-1
./scripts/setup-backend.sh staging us-east-1 staging

# Repeat for other regions/environments
./scripts/setup-backend.sh staging eu-central-1 staging
./scripts/setup-backend.sh production us-east-1 production
./scripts/setup-backend.sh production eu-central-1 production
```

### Step 2: Deploy Infrastructure
```bash
# Deploy staging infrastructure
./scripts/deploy-infrastructure.sh staging us-east-1 apply
./scripts/deploy-infrastructure.sh staging eu-central-1 apply

# Deploy production infrastructure
./scripts/deploy-infrastructure.sh production us-east-1 apply
./scripts/deploy-infrastructure.sh production eu-central-1 apply
```

### Step 3: Configure kubectl
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
- **Domain**: sre-challenge-staging.local

### Production Environment
- **Deletion Protection**: Enabled (data protection)
- **Log Retention**: 30 days
- **Node Groups**: On-demand instances only (reliability)
- **Force Destroy**: Disabled (data protection)
- **Domain**: sre-challenge-production.local

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

## Cost Optimization

### Staging Environment
- **Spot Instances**: 50% cost reduction for non-critical workloads
- **Minimal Node Count**: Start with 2 nodes, scale as needed
- **Lifecycle Policies**: Automatic cleanup of old artifacts

### Production Environment
- **Reserved Instances**: Consider RI for predictable workloads
- **Auto Scaling**: Automatic scaling based on demand
- **Storage Classes**: Use IA/Glacier for long-term storage

## Next Steps - Phase 2: Flux Installation

1. **Install Flux**: Bootstrap GitOps workflow
2. **Repository Structure**: Create GitOps repository layout
3. **Application Manifests**: Prepare Kubernetes deployments
4. **Automated Deployment**: Configure continuous deployment

## Support & Troubleshooting

### Common Issues

1. **Backend Bucket Not Found**
   ```bash
   # Run backend setup first
   ./scripts/setup-backend.sh staging us-east-1 staging
   ```

2. **Permission Denied**
   ```bash
   # Check AWS credentials
   aws sts get-caller-identity --profile staging
   ```

3. **Terraform Lock**
   ```bash
   # If stuck, force unlock (use carefully)
   terraform force-unlock <LOCK_ID>
   ```

### Getting Help
- Check terraform/README.md for detailed documentation
- Review AWS CloudTrail for deployment events
- Use `terraform plan` to preview changes before applying

This completes **Phase 1: Cluster Setup** with enterprise-grade infrastructure ready for GitOps deployment!