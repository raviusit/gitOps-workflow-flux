# Global Variables for Staging Environment

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "sre-challenge"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "staging"
}

# Route53 Variables
variable "domain_name" {
  description = "The domain name for the hosted zone"
  type        = string
  default     = "sre-challenge-panther.network"
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

variable "route53_force_destroy" {
  description = "Whether to destroy all records in the hosted zone on destroy"
  type        = bool
  default     = true
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

# S3 Variables for Global Buckets
variable "global_s3_buckets" {
  description = "Map of global S3 buckets to create"
  type = map(object({
    purpose                   = string
    force_destroy            = bool
    versioning_enabled       = bool
    kms_key_id              = string
    block_public_acls       = bool
    block_public_policy     = bool
    ignore_public_acls      = bool
    restrict_public_buckets = bool
    bucket_policy           = string
    lifecycle_rules = list(object({
      id     = string
      status = string
      expiration = object({
        days = number
      })
      noncurrent_version_expiration = object({
        noncurrent_days = number
      })
      transitions = list(object({
        days          = number
        storage_class = string
      }))
      noncurrent_version_transitions = list(object({
        noncurrent_days = number
        storage_class   = string
      }))
      filter = object({
        prefix = string
      })
    }))
    notification_configurations = list(object({
      type          = string
      function_arn  = string
      queue_arn     = string
      topic_arn     = string
      events        = list(string)
      filter_prefix = string
      filter_suffix = string
    }))
    cors_rules = list(object({
      allowed_headers = list(string)
      allowed_methods = list(string)
      allowed_origins = list(string)
      expose_headers  = list(string)
      max_age_seconds = number
    }))
    website_configuration = object({
      index_document = string
      error_document = string
      redirect_all_requests_to = object({
        host_name = string
        protocol  = string
      })
    })
  }))
  default = {
    global-configs = {
      purpose                      = "Global configuration files and templates"
      force_destroy               = true
      versioning_enabled          = true
      kms_key_id                  = ""
      block_public_acls           = true
      block_public_policy         = true
      ignore_public_acls          = true
      restrict_public_buckets     = true
      bucket_policy               = ""
      lifecycle_rules             = []
      notification_configurations = []
      cors_rules                  = []
      website_configuration       = null
    }
  }
}

variable "s3_create_kms_key" {
  description = "Controls if a KMS key for S3 encryption should be created"
  type        = bool
  default     = true
}