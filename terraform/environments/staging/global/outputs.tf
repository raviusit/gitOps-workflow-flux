# Global Outputs for Staging Environment

# IAM Outputs
output "eks_cluster_role_arn" {
  description = "ARN of the EKS cluster IAM role"
  value       = module.iam_basic.eks_cluster_role_arn
}

output "eks_cluster_role_name" {
  description = "Name of the EKS cluster IAM role"
  value       = module.iam_basic.eks_cluster_role_name
}

output "eks_node_group_role_arn" {
  description = "ARN of the EKS node group IAM role"
  value       = module.iam_basic.eks_node_group_role_arn
}

output "eks_node_group_role_name" {
  description = "Name of the EKS node group IAM role"
  value       = module.iam_basic.eks_node_group_role_name
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = module.iam_basic.ecr_repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  value       = module.iam_basic.ecr_repository_arn
}

# Route53 Outputs
output "hosted_zone_id" {
  description = "Route53 hosted zone ID"
  value       = module.route53.hosted_zone_id
}

output "hosted_zone_arn" {
  description = "Route53 hosted zone ARN"
  value       = module.route53.hosted_zone_arn
}

output "hosted_zone_name_servers" {
  description = "Route53 hosted zone name servers"
  value       = module.route53.hosted_zone_name_servers
}

output "certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = module.route53.certificate_arn
}

output "domain_name" {
  description = "Domain name of the hosted zone"
  value       = module.route53.domain_name
}

# S3 Outputs
output "global_s3_bucket_ids" {
  description = "Map of global S3 bucket IDs"
  value       = module.s3_global.bucket_ids
}

output "global_s3_bucket_arns" {
  description = "Map of global S3 bucket ARNs"
  value       = module.s3_global.bucket_arns
}

# Common Outputs
output "account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "project_name" {
  description = "Project name"
  value       = var.project_name
}