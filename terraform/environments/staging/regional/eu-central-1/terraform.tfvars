# Regional Configuration for Staging eu-central-1
project_name = "sre-challenge"
environment  = "staging"
aws_region   = "eu-central-1"

# Domain from global resources
domain_name = "eu-central-1.sre-challenge-panther.network"

# VPC Configuration (Different CIDR to avoid conflicts)
vpc_cidr                 = "10.1.0.0/16"
public_subnet_cidrs      = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
private_subnet_cidrs     = ["10.1.4.0/24", "10.1.5.0/24", "10.1.6.0/24"]
database_subnet_cidrs    = ["10.1.7.0/24", "10.1.8.0/24", "10.1.9.0/24"]
enable_nat_gateway       = true
enable_flow_logs         = true

# EKS Configuration
cluster_version                        = "1.31"
cluster_endpoint_private_access        = true
cluster_endpoint_public_access         = true
cluster_endpoint_public_access_cidrs   = ["92.72.32.195/32"]
cluster_enabled_log_types              = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
cloudwatch_log_group_retention_in_days = 7
workstation_cidr_blocks                = []

# Node Groups Configuration
node_groups = {
  general = {
    capacity_type              = "ON_DEMAND"
    instance_types             = ["t3.medium"]
    ami_type                   = "AL2_x86_64"
    disk_size                  = 50
    desired_size               = 2
    max_size                   = 3
    min_size                   = 1
    max_unavailable_percentage = 25
    labels = {
      role = "general"
    }
    taints          = []
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

# ALB Configuration
alb_internal                         = false
alb_enable_deletion_protection       = false
alb_enable_cross_zone_load_balancing = true
alb_enable_http2                     = true
alb_idle_timeout                     = 60
alb_access_logs_enabled              = false
alb_access_logs_bucket               = ""
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
    cidr_blocks = ["92.72.32.195/32", "92.72.32.196/32"]
  },
  {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["92.72.32.195/32", "92.72.32.196/32"]
  }
]

# Regional S3 Configuration
regional_s3_buckets = {
  regional-artifacts = {
    purpose                      = "Regional artifacts and logs for eu-central-1"
    force_destroy               = true
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
        days = 60
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
create_kms_key    = true