output "certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = aws_acm_certificate_validation.app_cert.certificate_arn
}

output "domain_name" {
  description = "Domain name of the certificate"
  value       = aws_acm_certificate.app_cert.domain_name
}

# DNS record FQDN output removed - handled separately to avoid circular dependency