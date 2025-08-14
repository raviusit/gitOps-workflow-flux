output "alb_record_name" {
  description = "Name of the ALB DNS record"
  value       = aws_route53_record.alb.name
}

output "alb_record_fqdn" {
  description = "FQDN of the ALB DNS record"
  value       = aws_route53_record.alb.fqdn
}

output "wildcard_record_name" {
  description = "Name of the wildcard DNS record"
  value       = var.create_wildcard_record ? aws_route53_record.alb_wildcard[0].name : null
}

output "wildcard_record_fqdn" {
  description = "FQDN of the wildcard DNS record"
  value       = var.create_wildcard_record ? aws_route53_record.alb_wildcard[0].fqdn : null
}