# Regional Configuration for Production eu-central-1
project_name = "sre-challenge"
environment  = "production"
aws_region   = "eu-central-1"

# Domain from global resources
domain_name = "sre-challenge-production.local"

# VPC Configuration (Different CIDR to avoid conflicts)
vpc_cidr                 = "10.1.0.0/16"
public_subnet_cidrs      = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
private_subnet_cidrs     = ["10.1.4.0/24", "10.1.5.0/24", "10.1.6.0/24"]
database_subnet_cidrs    = ["10.1.7.0/24", "10.1.8.0/24", "10.1.9.0/24"]
enable_nat_gateway       = true
enable_flow_logs         = true

# EKS Configuration (Production settings)
cluster_version                        = "1.31"
cluster_endpoint_private_access        = true
cluster_endpoint_public_access         = false
cluster_endpoint_public_access_cidrs   = ["92.72.32.195/32"]
cluster_enabled_log_types              = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
cloudwatch_log_group_retention_in_days = 30  # Longer retention for production
workstation_cidr_blocks                = []

# Node Groups Configuration (Production sizing)
node_groups = {
  general = {
    capacity_type              = "ON_DEMAND"
    instance_types             = ["m5.large"]  # Larger instances for production
    ami_type                   = "AL2_x86_64"
    disk_size                  = 100  # More storage for production
    desired_size               = 3    # Higher capacity for production
    max_size                   = 6
    min_size                   = 2
    max_unavailable_percentage = 25
    labels = {
      role = "general"
      env  = "production"
    }
    taints          = []
    launch_template = null
    remote_access   = null
  }
  spot = {
    capacity_type              = "SPOT"
    instance_types             = ["m5.large", "m5a.large", "m4.large"]  # Mixed instances for cost optimization
    ami_type                   = "AL2_x86_64"
    disk_size                  = 100
    desired_size               = 2
    max_size                   = 4
    min_size                   = 0
    max_unavailable_percentage = 50  # Higher unavailable percentage for spot
    labels = {
      role = "spot"
      env  = "production"
    }
    taints = [{
      key    = "spot-instance"
      value  = "true"
      effect = "NO_SCHEDULE"
    }]
    launch_template = null
    remote_access   = null
  }
}

# EKS Add-ons (EBS CSI will be added with IRSA role)
cluster_addons = {
  coredns = {
    addon_version            = ""
    resolve_conflicts        = "OVERWRITE"
    service_account_role_arn = ""
  }
  kube-proxy = {
    addon_version            = ""
    resolve_conflicts        = "OVERWRITE"
    service_account_role_arn = ""
  }
  vpc-cni = {
    addon_version            = ""
    resolve_conflicts        = "OVERWRITE"
    service_account_role_arn = ""
  }
}

# ALB Configuration (Production settings)
alb_internal                         = false
alb_enable_deletion_protection       = true   # Enable deletion protection for production
alb_enable_cross_zone_load_balancing = true
alb_enable_http2                     = true
alb_idle_timeout                     = 60
alb_access_logs_enabled              = true   # Enable access logs for production
alb_access_logs_bucket               = ""     # Will use regional bucket
alb_access_logs_prefix               = "alb-logs"
alb_enable_http_listener             = true
alb_enable_https_listener            = true
alb_ssl_policy                       = "ELBSecurityPolicy-TLS-1-2-2017-01"

# ALB Ingress Rules
alb_ingress_rules = [
  {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  },
  {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
]

# Regional S3 Configuration (Production buckets)
regional_s3_buckets = {
  regional-artifacts = {
    purpose                      = "Regional artifacts and logs for production eu-central-1"
    force_destroy               = false  # Don't allow force destroy in production
    versioning_enabled          = true
    kms_key_id                  = ""
    block_public_acls           = true
    block_public_policy         = true
    ignore_public_acls          = true
    restrict_public_buckets     = true
    bucket_policy               = ""
    lifecycle_rules = [{
      id     = "cleanup-regional-artifacts"
      status = "Enabled"
      expiration = {
        days = 365  # Longer retention for production
      }
      noncurrent_version_expiration = {
        noncurrent_days = 90  # Longer retention for production
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
  alb-access-logs = {
    purpose                      = "ALB access logs for production eu-central-1"
    force_destroy               = false
    versioning_enabled          = false  # ALB logs don't need versioning
    kms_key_id                  = ""
    block_public_acls           = true
    block_public_policy         = true
    ignore_public_acls          = true
    restrict_public_buckets     = true
    bucket_policy               = ""
    lifecycle_rules = [{
      id     = "cleanup-alb-logs"
      status = "Enabled"
      expiration = {
        days = 90  # Keep ALB logs for 90 days
      }
      noncurrent_version_expiration = {
        noncurrent_days = 90
      }
      transitions = [{
        days          = 30
        storage_class = "STANDARD_IA"
      }]
      noncurrent_version_transitions = []
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