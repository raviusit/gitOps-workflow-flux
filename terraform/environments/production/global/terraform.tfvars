# Global Configuration for Production
project_name = "sre-challenge"
environment  = "production"

# Domain Configuration
domain_name = "sre-challenge-panther.network"
create_hosted_zone = true

# ECR Configuration
create_ecr_repositories = true
ecr_repositories = {
  app = {
    name                 = "sre-challenge-app"
    image_tag_mutability = "MUTABLE"
    scan_on_push        = true
    force_delete        = false
    lifecycle_policy = {
      rules = [
        {
          rulePriority = 1
          description  = "Keep last 10 production images"
          selection = {
            tagStatus     = "tagged"
            tagPrefixList = ["prod"]
            countType     = "imageCountMoreThan"
            countNumber   = 10
          }
          action = {
            type = "expire"
          }
        },
        {
          rulePriority = 2
          description  = "Keep last 5 staging images"
          selection = {
            tagStatus     = "tagged"
            tagPrefixList = ["staging"]
            countType     = "imageCountMoreThan"
            countNumber   = 5
          }
          action = {
            type = "expire"
          }
        },
        {
          rulePriority = 3
          description  = "Delete untagged images after 1 day"
          selection = {
            tagStatus   = "untagged"
            countType   = "sinceImagePushed"
            countUnit   = "days"
            countNumber = 1
          }
          action = {
            type = "expire"
          }
        }
      ]
    }
  }
  flux-system = {
    name                 = "sre-challenge-flux"
    image_tag_mutability = "IMMUTABLE"
    scan_on_push        = true
    force_delete        = false
    lifecycle_policy = {
      rules = [
        {
          rulePriority = 1
          description  = "Keep last 15 production images"
          selection = {
            tagStatus     = "tagged"
            tagPrefixList = ["v"]
            countType     = "imageCountMoreThan"
            countNumber   = 15
          }
          action = {
            type = "expire"
          }
        }
      ]
    }
  }
}

# Global S3 Configuration
global_s3_buckets = {
  terraform-state = {
    purpose                      = "Terraform state storage for production"
    force_destroy               = false
    versioning_enabled          = true
    kms_key_id                  = ""
    block_public_acls           = true
    block_public_policy         = true
    ignore_public_acls          = true
    restrict_public_buckets     = true
    bucket_policy               = ""
    lifecycle_rules = [{
      id     = "terraform-state-lifecycle"
      status = "Enabled"
      expiration = {
        days = 0  # Never delete
      }
      noncurrent_version_expiration = {
        noncurrent_days = 90  # Keep old versions for 90 days
      }
      transitions = []
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
  artifacts-global = {
    purpose                      = "Global artifacts and shared resources"
    force_destroy               = false
    versioning_enabled          = true
    kms_key_id                  = ""
    block_public_acls           = true
    block_public_policy         = true
    ignore_public_acls          = true
    restrict_public_buckets     = true
    bucket_policy               = ""
    lifecycle_rules = [{
      id     = "cleanup-global-artifacts"
      status = "Enabled"
      expiration = {
        days = 365  # Keep for 1 year
      }
      noncurrent_version_expiration = {
        noncurrent_days = 90
      }
      transitions = [{
        days          = 30
        storage_class = "STANDARD_IA"
      }, {
        days          = 90
        storage_class = "GLACIER"
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
create_kms_key    = true