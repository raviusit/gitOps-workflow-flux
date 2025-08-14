output "bucket_ids" {
  description = "Map of S3 bucket IDs"
  value       = { for k, v in aws_s3_bucket.main : k => v.id }
}

output "bucket_arns" {
  description = "Map of S3 bucket ARNs"
  value       = { for k, v in aws_s3_bucket.main : k => v.arn }
}

output "bucket_domain_names" {
  description = "Map of S3 bucket domain names"
  value       = { for k, v in aws_s3_bucket.main : k => v.bucket_domain_name }
}

output "bucket_regional_domain_names" {
  description = "Map of S3 bucket regional domain names"
  value       = { for k, v in aws_s3_bucket.main : k => v.bucket_regional_domain_name }
}

output "bucket_hosted_zone_ids" {
  description = "Map of S3 bucket hosted zone IDs"
  value       = { for k, v in aws_s3_bucket.main : k => v.hosted_zone_id }
}

output "bucket_regions" {
  description = "Map of S3 bucket regions"
  value       = { for k, v in aws_s3_bucket.main : k => v.region }
}

output "website_endpoints" {
  description = "Map of S3 bucket website endpoints"
  value       = { for k, v in aws_s3_bucket_website_configuration.main : k => v.website_endpoint }
}

output "website_domains" {
  description = "Map of S3 bucket website domains"
  value       = { for k, v in aws_s3_bucket_website_configuration.main : k => v.website_domain }
}

output "kms_key_id" {
  description = "The globally unique identifier for the KMS key"
  value       = var.create_kms_key ? aws_kms_key.s3[0].key_id : null
}

output "kms_key_arn" {
  description = "The Amazon Resource Name (ARN) of the KMS key"
  value       = var.create_kms_key ? aws_kms_key.s3[0].arn : null
}