# Terraform Infrastructure for SRE Challenge

This repository contains Terraform modules and configurations for deploying AWS infrastructure across multiple environments and regions.

## Repository Structure

```
terraform/
├── backend/                    # Backend configuration for Terraform state
├── modules/                    # Reusable Terraform modules
│   ├── iam/                   # IAM roles and policies
│   ├── vpc/                   # VPC, subnets, security groups
│   ├── eks/                   # EKS cluster and node groups
│   ├── alb/                   # Application Load Balancer
│   ├── route53/               # DNS and SSL certificates
│   └── s3/                    # S3 buckets and policies
└── environments/               # Environment-specific configurations
    ├── staging/               # Staging environment (Account: 215876814712)
    │   ├── us-east-1/         # US East 1 region
    │   └── eu-central-1/      # EU Central 1 region
    └── production/            # Production environment (Account: 746848447423)
        ├── us-east-1/         # US East 1 region
        └── eu-central-1/      # EU Central 1 region
```

## Prerequisites

1. **AWS CLI configured** with appropriate profiles:
   ```bash
   # Configure AWS profiles
   aws configure --profile staging
   aws configure --profile production
   ```

2. **Terraform installed** (version >= 1.0)
   ```bash
   terraform --version
   ```

3. **kubectl installed** for EKS cluster management
   ```bash
   kubectl version --client
   ```

## Deployment Steps

### Step 1: Initialize Backend (First Time Only)

Before deploying any infrastructure, you need to create the Terraform backend resources:

```bash
# Create backend for staging us-east-1
cd terraform/backend
terraform init
terraform plan -var="environment=staging" -var="region=us-east-1"
terraform apply -var="environment=staging" -var="region=us-east-1"

# Repeat for other environments/regions
terraform apply -var="environment=staging" -var="region=eu-central-1"
terraform apply -var="environment=production" -var="region=us-east-1"
terraform apply -var="environment=production" -var="region=eu-central-1"
```

### Step 2: Deploy Infrastructure

For each environment and region:

```bash
# Example: Deploy staging infrastructure in us-east-1
cd terraform/environments/staging/us-east-1

# Initialize with backend configuration
terraform init -backend-config=backend.hcl

# Plan the deployment
terraform plan -var-file=terraform.tfvars

# Apply the configuration
terraform apply -var-file=terraform.tfvars
```

### Step 3: Configure kubectl

After EKS cluster deployment:

```bash
# Update kubeconfig for the cluster
aws eks update-kubeconfig --region us-east-1 --name sre-challenge-staging --profile staging
```

## Security Features

### Network Security
- **Private subnets** for EKS nodes
- **Security groups** with minimal required access
- **Network policies** for pod-to-pod communication
- **VPC Flow Logs** for network monitoring

### Identity & Access Management
- **RBAC** enabled on EKS clusters
- **OIDC provider** for service account integration
- **Least privilege** IAM roles and policies
- **Service-specific roles** for AWS Load Balancer Controller and Flux

### Data Protection
- **Encryption at rest** using KMS keys
- **Encryption in transit** with TLS
- **S3 bucket policies** preventing public access
- **Secrets encryption** in EKS clusters

### Monitoring & Logging
- **CloudWatch logs** for EKS control plane
- **VPC Flow Logs** for network traffic
- **CloudTrail integration** for audit logging

## Network Architecture

### CIDR Allocation
- **Staging us-east-1**: 10.0.0.0/16
- **Staging eu-central-1**: 10.0.0.0/16
- **Production us-east-1**: 10.10.0.0/16
- **Production eu-central-1**: 10.20.0.0/16

### Subnet Strategy
- **Public subnets**: /24 networks (1-3)
- **Private subnets**: /24 networks (4-6)
- **Database subnets**: /24 networks (7-9)

## Environment Differences

### Staging
- **Deletion protection**: Disabled for easy cleanup
- **Log retention**: 7 days
- **Node groups**: Includes spot instances
- **Force destroy**: Enabled for Route53

### Production
- **Deletion protection**: Enabled for ALB
- **Log retention**: 30 days
- **Node groups**: On-demand instances only
- **Force destroy**: Disabled for Route53

## Useful Commands

```bash
# Get cluster info
kubectl cluster-info

# List nodes
kubectl get nodes

# Get pods in all namespaces
kubectl get pods --all-namespaces

# Get AWS Load Balancer Controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Describe EKS cluster
aws eks describe-cluster --name sre-challenge-staging --region us-east-1
```

## Troubleshooting

### Common Issues

1. **Backend bucket doesn't exist**
   - Run the backend configuration first
   - Check AWS credentials and permissions

2. **EKS cluster unreachable**
   - Update kubeconfig: `aws eks update-kubeconfig`
   - Check security group rules

3. **Pods stuck in pending**
   - Check node capacity: `kubectl describe nodes`
   - Verify node group configuration

### Cleanup

```bash
# Destroy infrastructure (be careful!)
cd terraform/environments/staging/us-east-1
terraform destroy -var-file=terraform.tfvars
```

## Next Steps

After infrastructure deployment:
1. Install Flux for GitOps (Phase 2)
2. Deploy sample applications (Phase 3)
3. Set up monitoring with Prometheus/Grafana (Phase 4)