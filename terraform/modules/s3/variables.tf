variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "buckets" {
  description = "Map of S3 buckets to create"
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
  default = {}
}

variable "create_kms_key" {
  description = "Controls if a KMS key for S3 encryption should be created"
  type        = bool
  default     = true
}

variable "kms_key_deletion_window_in_days" {
  description = "KMS key deletion window in days"
  type        = number
  default     = 10
}

variable "kms_key_enable_key_rotation" {
  description = "Specifies whether key rotation is enabled"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}