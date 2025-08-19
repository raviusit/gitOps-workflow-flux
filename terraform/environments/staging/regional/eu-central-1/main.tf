# Regional resources for staging eu-central-1
# These depend on global resources and create IRSA roles using EKS OIDC

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }

  backend "s3" {
    # Backend configuration provided during init
    # terraform init -backend-config=backend.hcl
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "staging-215876814712-raisin"

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      Region      = var.aws_region
      ManagedBy   = "Terraform"
      Scope       = "Regional"
    }
  }
}


# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Remote state from global resources
data "terraform_remote_state" "global" {
  backend = "s3"
  config = {
    bucket  = "sre-challenge-terraform-state-staging-global"
    key     = "global/terraform.tfstate"
    region  = "us-east-1"
    profile = "staging-215876814712-raisin"
  }
}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Region      = var.aws_region
    ManagedBy   = "Terraform"
    Scope       = "Regional"
  }

  # Get values from global state
  eks_cluster_role_arn    = data.terraform_remote_state.global.outputs.eks_cluster_role_arn
  eks_node_group_role_arn = data.terraform_remote_state.global.outputs.eks_node_group_role_arn
  hosted_zone_id          = data.terraform_remote_state.global.outputs.hosted_zone_id
}

# VPC Module
module "vpc" {
  source = "../../../../modules/vpc"

  project_name            = var.project_name
  environment             = var.environment
  vpc_cidr               = var.vpc_cidr
  public_subnet_cidrs    = var.public_subnet_cidrs
  private_subnet_cidrs   = var.private_subnet_cidrs
  database_subnet_cidrs  = var.database_subnet_cidrs
  enable_nat_gateway     = var.enable_nat_gateway
  enable_flow_logs       = var.enable_flow_logs

  tags = local.common_tags
}

# EKS Module (using global IAM roles)
module "eks" {
  source = "../../../../modules/eks"

  project_name                           = var.project_name
  environment                            = var.environment
  cluster_version                        = var.cluster_version
  cluster_service_role_arn               = local.eks_cluster_role_arn
  node_group_role_arn                    = local.eks_node_group_role_arn
  private_subnet_ids                     = module.vpc.private_subnet_ids
  public_subnet_ids                      = module.vpc.public_subnet_ids
  cluster_security_group_id              = module.vpc.eks_cluster_security_group_id
  cluster_endpoint_private_access        = var.cluster_endpoint_private_access
  cluster_endpoint_public_access         = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs   = var.cluster_endpoint_public_access_cidrs
  cluster_enabled_log_types              = var.cluster_enabled_log_types
  cloudwatch_log_group_retention_in_days = var.cloudwatch_log_group_retention_in_days
  workstation_cidr_blocks                = var.workstation_cidr_blocks
  node_groups                            = var.node_groups
  cluster_addons = var.cluster_addons
  create_kms_key                         = var.create_kms_key

  tags = local.common_tags

  depends_on = [module.vpc]
}

# IRSA IAM Module (uses OIDC URL from EKS cluster)
module "iam_irsa" {
  source = "../../../../modules/iam-irsa"

  project_name            = var.project_name
  environment             = var.environment
  cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url

  tags = local.common_tags

  depends_on = [module.eks]
}

# EBS CSI Driver Addon (created after IRSA roles)
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name                = module.eks.cluster_id
  addon_name                  = "aws-ebs-csi-driver"
  addon_version               = "v1.35.0-eksbuild.1"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  service_account_role_arn    = module.iam_irsa.ebs_csi_driver_role_arn

  depends_on = [module.iam_irsa]

  tags = local.common_tags
}

# ACM Certificate Module (using existing certificate)
# module "acm" {
#   source = "../../../../modules/acm"
#
#   domain_name     = var.domain_name
#   hosted_zone_id  = local.hosted_zone_id
#
#   tags = local.common_tags
# }

# ALB Module (uses IRSA roles)
module "alb" {
  source = "../../../../modules/alb"

  project_name                      = var.project_name
  environment                       = var.environment
  vpc_id                           = module.vpc.vpc_id
  public_subnet_ids                = module.vpc.public_subnet_ids
  private_subnet_ids               = module.vpc.private_subnet_ids
  internal                         = var.alb_internal
  enable_deletion_protection       = var.alb_enable_deletion_protection
  enable_cross_zone_load_balancing = var.alb_enable_cross_zone_load_balancing
  enable_http2                     = var.alb_enable_http2
  idle_timeout                     = var.alb_idle_timeout
  access_logs_enabled              = var.alb_access_logs_enabled
  access_logs_bucket               = var.alb_access_logs_bucket
  access_logs_prefix               = var.alb_access_logs_prefix
  ingress_rules                    = var.alb_ingress_rules
  enable_http_listener             = var.alb_enable_http_listener
  enable_https_listener            = var.alb_enable_https_listener
  certificate_arn                  = "arn:aws:acm:eu-central-1:215876814712:certificate/044d1363-c331-48a7-a093-44b8d558ea90"
  ssl_policy                       = var.alb_ssl_policy

  tags = local.common_tags

  depends_on = [module.vpc, module.iam_irsa]
}
    
# Regional S3 Module
module "s3_regional" {
  source = "../../../../modules/s3"

  project_name   = var.project_name
  environment    = var.environment
  buckets        = var.regional_s3_buckets
  create_kms_key = var.s3_create_kms_key

  tags = local.common_tags
}

# CloudFront Certificate Module (us-east-1 required for CloudFront)
module "acm_cloudfront" {
  source = "../../../../modules/acm-cloudfront"
  
  providers = {
    aws = aws.us_east_1
  }

  domain_name     = var.domain_name
  hosted_zone_id  = local.hosted_zone_id

  tags = local.common_tags
}

# CloudFront Distribution Module (commented out until ALB domain is known)
# module "cloudfront" {
#   source = "../../../../modules/cloudfront"

#   project_name    = var.project_name
#   environment     = var.environment
#   certificate_arn = module.acm_cloudfront.certificate_arn
  
#   # ALB domain names (will be discovered after ALB Controller creates them)
#   alb_domain_name = var.alb_domain_name
  
#   # Domain aliases
#   domain_aliases = [var.domain_name]
  
#   # CloudFront settings
#   price_class        = "PriceClass_100"  # US, Canada, Europe
#   default_cache_ttl  = 300   # 5 minutes
#   max_cache_ttl      = 86400 # 24 hours

#   tags = local.common_tags

#   depends_on = [module.acm_cloudfront]
# }

# CloudFront-compliant security group for ALB 
# Prefix list will be added via CLI to avoid Terraform rule limit issues
resource "aws_security_group" "cloudfront_alb" {
  name        = "${var.project_name}-cloudfront-alb-sg"
  description = "ALB security group for CloudFront access - Security Hub compliant"
  vpc_id      = module.vpc.vpc_id

  # VPC CIDR for internal access (Security Hub compliant)
  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  # VPC CIDR for internal access (Security Hub compliant)
  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-cloudfront-alb-sg"
    Type = "ALB-CloudFront"
    SecurityHubCompliant = "true"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# CloudFront prefix list rules will be added via external script
# to avoid Terraform security group rule limit issues

# DNS alias record is managed by Kubernetes AWS Load Balancer Controller
# Certificate is provided via ACM module for Kubernetes ingress to use

