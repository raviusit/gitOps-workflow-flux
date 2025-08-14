# Global Configuration for Staging Environment
project_name = "sre-challenge"
environment  = "staging"

# Route53 Configuration
domain_name                = "sre-challenge-staging.local"
create_hosted_zone         = true
hosted_zone_id             = ""
route53_force_destroy      = true
create_certificate         = false
subject_alternative_names  = []
enable_query_logging       = false
log_retention_in_days      = 7

# Global S3 Configuration
global_s3_buckets = {
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
    lifecycle_rules = [{
      id     = "retain-global-configs"
      status = "Enabled"
      expiration = {
        days = 90
      }
      noncurrent_version_expiration = {
        noncurrent_days = 60
      }
      transitions = [{
        days          = 30
        storage_class = "STANDARD_IA"
      }]
      noncurrent_version_transitions = [{
        noncurrent_days = 30
        storage_class   = "STANDARD_IA"
      }]
      filter = {
        prefix = ""
      }
    }]
    notification_configurations = []
    cors_rules                  = []
    website_configuration       = null
  }
}

s3_create_kms_key = true