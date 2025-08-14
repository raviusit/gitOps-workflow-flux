# Route53 records for regional ALB

# A Record for ALB
resource "aws_route53_record" "alb" {
  zone_id = var.hosted_zone_id
  name    = "${var.region}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# Optional: Create a region-specific wildcard record
resource "aws_route53_record" "alb_wildcard" {
  count = var.create_wildcard_record ? 1 : 0

  zone_id = var.hosted_zone_id
  name    = "*.${var.region}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}