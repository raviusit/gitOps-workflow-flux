# Global resources for staging environment
# These are account-wide resources deployed once per environment

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # Backend configuration provided during init
    # terraform init -backend-config=backend.hcl
  }
}

provider "aws" {
  region  = "us-east-1"  # Primary region for global resources
  profile = "staging-215876814712-raisin"

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Scope       = "Global"
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Scope       = "Global"
  }
}

# Basic IAM Module (without OIDC dependencies)
module "iam_basic" {
  source = "../../../modules/iam-basic"

  project_name = var.project_name
  environment  = var.environment

  tags = local.common_tags
}

# Route53 Module (Global DNS)
module "route53" {
  source = "../../../modules/route53"

  project_name              = var.project_name
  environment               = var.environment
  domain_name               = var.domain_name
  create_hosted_zone        = var.create_hosted_zone
  hosted_zone_id            = var.hosted_zone_id
  force_destroy             = var.route53_force_destroy
  create_certificate        = var.create_certificate
  subject_alternative_names = var.subject_alternative_names
  enable_query_logging      = var.enable_query_logging
  log_retention_in_days     = var.log_retention_in_days

  # No ALB DNS records in global - those are regional
  alb_dns_records = {}

  tags = local.common_tags
}

# S3 buckets for global artifacts (cross-region replication can be added later)
module "s3_global" {
  source = "../../../modules/s3"

  project_name   = var.project_name
  environment    = var.environment
  buckets        = var.global_s3_buckets
  create_kms_key = var.s3_create_kms_key

  tags = local.common_tags
}