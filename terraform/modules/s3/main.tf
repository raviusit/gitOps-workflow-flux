# S3 Bucket for applications and configs
resource "aws_s3_bucket" "main" {
  for_each = var.buckets

  bucket        = "${var.project_name}-${each.key}-${var.environment}-${random_string.bucket_suffix[each.key].result}"
  force_destroy = each.value.force_destroy

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${each.key}-${var.environment}"
    Purpose     = each.value.purpose
    Environment = var.environment
  })
}

# Random string for bucket naming uniqueness
resource "random_string" "bucket_suffix" {
  for_each = var.buckets

  length  = 8
  special = false
  upper   = false
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "main" {
  for_each = { for k, v in var.buckets : k => v if v.versioning_enabled }

  bucket = aws_s3_bucket.main[each.key].id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Server-side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  for_each = var.buckets

  bucket = aws_s3_bucket.main[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = each.value.kms_key_id != "" ? "aws:kms" : "AES256"
      kms_master_key_id = each.value.kms_key_id != "" ? each.value.kms_key_id : null
    }
    bucket_key_enabled = each.value.kms_key_id != "" ? true : false
  }
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "main" {
  for_each = var.buckets

  bucket = aws_s3_bucket.main[each.key].id

  block_public_acls       = each.value.block_public_acls
  block_public_policy     = each.value.block_public_policy
  ignore_public_acls      = each.value.ignore_public_acls
  restrict_public_buckets = each.value.restrict_public_buckets
}

# S3 Bucket Lifecycle Configuration
resource "aws_s3_bucket_lifecycle_configuration" "main" {
  for_each = { for k, v in var.buckets : k => v if length(v.lifecycle_rules) > 0 }

  bucket = aws_s3_bucket.main[each.key].id

  dynamic "rule" {
    for_each = each.value.lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.status

      dynamic "expiration" {
        for_each = rule.value.expiration != null ? [rule.value.expiration] : []
        content {
          days = expiration.value.days
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = rule.value.noncurrent_version_expiration != null ? [rule.value.noncurrent_version_expiration] : []
        content {
          noncurrent_days = noncurrent_version_expiration.value.noncurrent_days
        }
      }

      dynamic "transition" {
        for_each = rule.value.transitions
        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }

      dynamic "noncurrent_version_transition" {
        for_each = rule.value.noncurrent_version_transitions
        content {
          noncurrent_days = noncurrent_version_transition.value.noncurrent_days
          storage_class   = noncurrent_version_transition.value.storage_class
        }
      }

      dynamic "filter" {
        for_each = rule.value.filter != null ? [rule.value.filter] : []
        content {
          prefix = filter.value.prefix
        }
      }
    }
  }
}

# S3 Bucket Policy
resource "aws_s3_bucket_policy" "main" {
  for_each = { for k, v in var.buckets : k => v if v.bucket_policy != "" }

  bucket = aws_s3_bucket.main[each.key].id
  policy = each.value.bucket_policy
}

# S3 Bucket Notification
resource "aws_s3_bucket_notification" "main" {
  for_each = { for k, v in var.buckets : k => v if length(v.notification_configurations) > 0 }

  bucket = aws_s3_bucket.main[each.key].id

  dynamic "lambda_function" {
    for_each = [for nc in each.value.notification_configurations : nc if nc.type == "lambda"]
    content {
      lambda_function_arn = lambda_function.value.function_arn
      events              = lambda_function.value.events
      filter_prefix       = lambda_function.value.filter_prefix
      filter_suffix       = lambda_function.value.filter_suffix
    }
  }

  dynamic "queue" {
    for_each = [for nc in each.value.notification_configurations : nc if nc.type == "sqs"]
    content {
      queue_arn     = queue.value.queue_arn
      events        = queue.value.events
      filter_prefix = queue.value.filter_prefix
      filter_suffix = queue.value.filter_suffix
    }
  }

  dynamic "topic" {
    for_each = [for nc in each.value.notification_configurations : nc if nc.type == "sns"]
    content {
      topic_arn     = topic.value.topic_arn
      events        = topic.value.events
      filter_prefix = topic.value.filter_prefix
      filter_suffix = topic.value.filter_suffix
    }
  }
}

# S3 Bucket CORS Configuration
resource "aws_s3_bucket_cors_configuration" "main" {
  for_each = { for k, v in var.buckets : k => v if length(v.cors_rules) > 0 }

  bucket = aws_s3_bucket.main[each.key].id

  dynamic "cors_rule" {
    for_each = each.value.cors_rules
    content {
      allowed_headers = cors_rule.value.allowed_headers
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      expose_headers  = cors_rule.value.expose_headers
      max_age_seconds = cors_rule.value.max_age_seconds
    }
  }
}

# S3 Bucket Website Configuration
resource "aws_s3_bucket_website_configuration" "main" {
  for_each = { for k, v in var.buckets : k => v if v.website_configuration != null }

  bucket = aws_s3_bucket.main[each.key].id

  dynamic "index_document" {
    for_each = each.value.website_configuration.index_document != null ? [each.value.website_configuration.index_document] : []
    content {
      suffix = index_document.value
    }
  }

  dynamic "error_document" {
    for_each = each.value.website_configuration.error_document != null ? [each.value.website_configuration.error_document] : []
    content {
      key = error_document.value
    }
  }

  dynamic "redirect_all_requests_to" {
    for_each = each.value.website_configuration.redirect_all_requests_to != null ? [each.value.website_configuration.redirect_all_requests_to] : []
    content {
      host_name = redirect_all_requests_to.value.host_name
      protocol  = redirect_all_requests_to.value.protocol
    }
  }
}

# KMS Key for S3 encryption
resource "aws_kms_key" "s3" {
  count = var.create_kms_key ? 1 : 0

  description             = "KMS key for S3 bucket encryption in ${var.environment}"
  deletion_window_in_days = var.kms_key_deletion_window_in_days
  enable_key_rotation     = var.kms_key_enable_key_rotation

  tags = merge(var.tags, {
    Name = "${var.project_name}-s3-kms-${var.environment}"
  })
}

resource "aws_kms_alias" "s3" {
  count = var.create_kms_key ? 1 : 0

  name          = "alias/${var.project_name}-s3-${var.environment}"
  target_key_id = aws_kms_key.s3[0].key_id
}