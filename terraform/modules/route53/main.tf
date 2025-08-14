# Route53 Hosted Zone
resource "aws_route53_zone" "main" {
  count = var.create_hosted_zone ? 1 : 0

  name          = var.domain_name
  comment       = "Hosted zone for ${var.project_name}-${var.environment}"
  force_destroy = var.force_destroy

  dynamic "vpc" {
    for_each = var.vpc_id != "" ? [1] : []
    content {
      vpc_id = var.vpc_id
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-hz-${var.environment}"
  })
}

# ACM Certificate
resource "aws_acm_certificate" "main" {
  count = var.create_certificate ? 1 : 0

  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-cert-${var.environment}"
  })
}

# Certificate Validation Records
resource "aws_route53_record" "cert_validation" {
  for_each = var.create_certificate && var.create_hosted_zone ? {
    for dvo in aws_acm_certificate.main[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.main[0].zone_id
}

# Certificate Validation
resource "aws_acm_certificate_validation" "main" {
  count = var.create_certificate && var.create_hosted_zone ? 1 : 0

  certificate_arn         = aws_acm_certificate.main[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]

  timeouts {
    create = "10m"
  }
}

# A Record for ALB
resource "aws_route53_record" "alb" {
  for_each = var.alb_dns_records

  zone_id = var.create_hosted_zone ? aws_route53_zone.main[0].zone_id : var.hosted_zone_id
  name    = each.key
  type    = "A"

  alias {
    name                   = each.value.dns_name
    zone_id                = each.value.zone_id
    evaluate_target_health = each.value.evaluate_target_health
  }
}

# CNAME Records
resource "aws_route53_record" "cname" {
  for_each = var.cname_records

  zone_id = var.create_hosted_zone ? aws_route53_zone.main[0].zone_id : var.hosted_zone_id
  name    = each.key
  type    = "CNAME"
  ttl     = each.value.ttl
  records = [each.value.record]
}

# TXT Records
resource "aws_route53_record" "txt" {
  for_each = var.txt_records

  zone_id = var.create_hosted_zone ? aws_route53_zone.main[0].zone_id : var.hosted_zone_id
  name    = each.key
  type    = "TXT"
  ttl     = each.value.ttl
  records = each.value.records
}

# MX Records
resource "aws_route53_record" "mx" {
  for_each = var.mx_records

  zone_id = var.create_hosted_zone ? aws_route53_zone.main[0].zone_id : var.hosted_zone_id
  name    = each.key
  type    = "MX"
  ttl     = each.value.ttl
  records = each.value.records
}

# Health Checks
resource "aws_route53_health_check" "main" {
  for_each = var.health_checks

  fqdn                            = each.value.fqdn
  port                            = each.value.port
  type                            = each.value.type
  resource_path                   = each.value.resource_path
  failure_threshold               = each.value.failure_threshold
  request_interval                = each.value.request_interval
  cloudwatch_alarm_region         = each.value.cloudwatch_alarm_region
  cloudwatch_alarm_name           = each.value.cloudwatch_alarm_name
  insufficient_data_health_status = each.value.insufficient_data_health_status

  tags = merge(var.tags, {
    Name = "${var.project_name}-hc-${each.key}-${var.environment}"
  })
}

# Route53 Query Logging
resource "aws_route53_query_log" "main" {
  count = var.enable_query_logging && var.create_hosted_zone ? 1 : 0

  depends_on = [aws_cloudwatch_log_group.route53]

  cloudwatch_log_group_arn = aws_cloudwatch_log_group.route53[0].arn
  zone_id                  = aws_route53_zone.main[0].zone_id
}

resource "aws_cloudwatch_log_group" "route53" {
  count = var.enable_query_logging && var.create_hosted_zone ? 1 : 0

  name              = "/aws/route53/${var.domain_name}"
  retention_in_days = var.log_retention_in_days

  tags = var.tags
}

# Route53 Resolver Rules (for Private Hosted Zones)
resource "aws_route53_resolver_rule" "main" {
  for_each = var.resolver_rules

  domain_name = each.value.domain_name
  rule_type   = each.value.rule_type
  resolver_endpoint_id = each.value.resolver_endpoint_id
  
  dynamic "target_ip" {
    for_each = each.value.target_ips
    content {
      ip   = target_ip.value.ip
      port = target_ip.value.port
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-resolver-rule-${each.key}-${var.environment}"
  })
}

# Route53 Resolver Rule Associations
resource "aws_route53_resolver_rule_association" "main" {
  for_each = var.resolver_rule_associations

  resolver_rule_id = aws_route53_resolver_rule.main[each.value.rule_key].id
  vpc_id           = each.value.vpc_id
}