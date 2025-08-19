# Regional Outputs for Staging eu-central-1

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

output "database_subnet_ids" {
  description = "IDs of the database subnets"
  value       = module.vpc.database_subnet_ids
}

output "eks_cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "eks_cluster_arn" {
  description = "EKS cluster ARN"
  value       = module.eks.cluster_arn
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_version" {
  description = "EKS cluster version"
  value       = module.eks.cluster_version
}

output "eks_cluster_oidc_issuer_url" {
  description = "EKS cluster OIDC issuer URL"
  value       = module.eks.cluster_oidc_issuer_url
}

output "eks_cluster_certificate_authority_data" {
  description = "EKS cluster certificate authority data"
  value       = module.eks.cluster_certificate_authority_data
}

output "eks_node_groups" {
  description = "EKS node groups"
  value       = module.eks.node_groups
}

# ALB outputs removed - ALBs now managed by AWS Load Balancer Controller

# IRSA Role ARNs
output "aws_load_balancer_controller_role_arn" {
  description = "ARN of the AWS Load Balancer Controller IAM role"
  value       = module.iam_irsa.aws_load_balancer_controller_role_arn
}

output "flux_controller_role_arn" {
  description = "ARN of the Flux Controller IAM role"
  value       = module.iam_irsa.flux_controller_role_arn
}

output "ebs_csi_driver_role_arn" {
  description = "ARN of the EBS CSI Driver IAM role"
  value       = module.iam_irsa.ebs_csi_driver_role_arn
}

# S3 Bucket Information
output "regional_s3_bucket_ids" {
  description = "IDs of the regional S3 buckets"
  value       = module.s3_regional.bucket_ids
}

output "regional_s3_bucket_arns" {
  description = "ARNs of the regional S3 buckets"
  value       = module.s3_regional.bucket_arns
}

# ACM Certificate (using existing certificate)
# output "certificate_arn" {
#   description = "ARN of the ACM certificate"
#   value       = module.acm.certificate_arn
# }

# output "certificate_domain_name" {
#   description = "Domain name of the certificate"
#   value       = module.acm.domain_name
# }

output "alb_record_fqdn" {
  description = "FQDN of the DNS record pointing to ALB (managed by Kubernetes)"
  value       = var.domain_name
}

# Environment Information
output "region" {
  description = "AWS region"
  value       = var.aws_region
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "project_name" {
  description = "Project name"
  value       = var.project_name
}

# CloudFront Distribution (commented out until ALB domain is known)
# output "cloudfront_distribution_id" {
#   description = "CloudFront distribution ID"
#   value       = module.cloudfront.distribution_id
# }

# output "cloudfront_distribution_domain_name" {
#   description = "CloudFront distribution domain name"
#   value       = module.cloudfront.distribution_domain_name
# }

output "cloudfront_certificate_arn" {
  description = "CloudFront certificate ARN (us-east-1)"
  value       = module.acm_cloudfront.certificate_arn
}

output "cloudfront_alb_security_group_id" {
  description = "Security group ID for CloudFront-compatible ALB (Security Hub compliant)"
  value       = aws_security_group.cloudfront_alb.id
}

# ALB resources are now fully managed by AWS Load Balancer Controller