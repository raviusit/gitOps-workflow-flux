variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "domain_name" {
  description = "The domain name for the hosted zone"
  type        = string
}

variable "create_hosted_zone" {
  description = "Whether to create a hosted zone"
  type        = bool
  default     = true
}

variable "hosted_zone_id" {
  description = "Existing hosted zone ID if not creating a new one"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "VPC ID for private hosted zone"
  type        = string
  default     = ""
}

variable "force_destroy" {
  description = "Whether to destroy all records in the hosted zone on destroy"
  type        = bool
  default     = false
}

variable "create_certificate" {
  description = "Whether to create an ACM certificate"
  type        = bool
  default     = true
}

variable "subject_alternative_names" {
  description = "A list of domains that should be SANs in the issued certificate"
  type        = list(string)
  default     = []
}

variable "alb_dns_records" {
  description = "Map of ALB DNS records to create"
  type = map(object({
    dns_name               = string
    zone_id                = string
    evaluate_target_health = bool
  }))
  default = {}
}

variable "cname_records" {
  description = "Map of CNAME records to create"
  type = map(object({
    ttl    = number
    record = string
  }))
  default = {}
}

variable "txt_records" {
  description = "Map of TXT records to create"
  type = map(object({
    ttl     = number
    records = list(string)
  }))
  default = {}
}

variable "mx_records" {
  description = "Map of MX records to create"
  type = map(object({
    ttl     = number
    records = list(string)
  }))
  default = {}
}

variable "health_checks" {
  description = "Map of health checks to create"
  type = map(object({
    fqdn                            = string
    port                            = number
    type                            = string
    resource_path                   = string
    failure_threshold               = number
    request_interval                = number
    cloudwatch_alarm_region         = string
    cloudwatch_alarm_name           = string
    insufficient_data_health_status = string
  }))
  default = {}
}

variable "enable_query_logging" {
  description = "Whether to enable Route53 query logging"
  type        = bool
  default     = false
}

variable "log_retention_in_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 7
}

variable "resolver_rules" {
  description = "Map of Route53 resolver rules to create"
  type = map(object({
    domain_name          = string
    rule_type           = string
    resolver_endpoint_id = string
    target_ips = list(object({
      ip   = string
      port = number
    }))
  }))
  default = {}
}

variable "resolver_rule_associations" {
  description = "Map of resolver rule associations to create"
  type = map(object({
    rule_key = string
    vpc_id   = string
  }))
  default = {}
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}