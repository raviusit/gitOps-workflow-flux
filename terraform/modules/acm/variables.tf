variable "domain_name" {
  description = "Domain name for the ACM certificate"
  type        = string
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID for DNS validation"
  type        = string
}

# ALB DNS name variable removed to break circular dependency

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}