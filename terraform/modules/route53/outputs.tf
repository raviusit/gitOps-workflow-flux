output "hosted_zone_id" {
  description = "Route53 hosted zone ID"
  value       = var.create_hosted_zone ? aws_route53_zone.main[0].zone_id : var.hosted_zone_id
}

output "hosted_zone_arn" {
  description = "Route53 hosted zone ARN"
  value       = var.create_hosted_zone ? aws_route53_zone.main[0].arn : null
}

output "hosted_zone_name_servers" {
  description = "Route53 hosted zone name servers"
  value       = var.create_hosted_zone ? aws_route53_zone.main[0].name_servers : null
}

output "certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = var.create_certificate ? aws_acm_certificate.main[0].arn : null
}

output "certificate_domain_name" {
  description = "Domain name of the ACM certificate"
  value       = var.create_certificate ? aws_acm_certificate.main[0].domain_name : null
}

output "certificate_status" {
  description = "Status of the ACM certificate"
  value       = var.create_certificate ? aws_acm_certificate.main[0].status : null
}

output "certificate_validation_arn" {
  description = "ARN of the validated ACM certificate"
  value       = var.create_certificate && var.create_hosted_zone ? aws_acm_certificate_validation.main[0].certificate_arn : null
}

output "domain_name" {
  description = "Domain name of the hosted zone"
  value       = var.domain_name
}

output "health_check_ids" {
  description = "Map of health check IDs"
  value       = { for k, v in aws_route53_health_check.main : k => v.id }
}

output "resolver_rule_ids" {
  description = "Map of resolver rule IDs"
  value       = { for k, v in aws_route53_resolver_rule.main : k => v.id }
}