# Regional Variables for Staging us-east-1

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

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "domain_name" {
  description = "Base domain name from global resources"
  type        = string
  default     = "sre-challenge-panther.network"
}

# VPC Variables
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "database_subnet_cidrs" {
  description = "CIDR blocks for database subnets"
  type        = list(string)
  default     = ["10.0.7.0/24", "10.0.8.0/24", "10.0.9.0/24"]
}

variable "enable_nat_gateway" {
  description = "Should be true if you want to provision NAT Gateways for each of your private networks"
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Should be true if you want to enable VPC Flow Logs"
  type        = bool
  default     = true
}

# EKS Variables
variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.31"
}

variable "cluster_endpoint_private_access" {
  description = "Indicates whether or not the Amazon EKS private API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled"
  type        = bool
  default     = false
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint"
  type        = list(string)
  default     = ["92.72.32.195/32"]
}

variable "cluster_enabled_log_types" {
  description = "A list of the desired control plane logging to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "Number of days to retain log events"
  type        = number
  default     = 7
}

variable "workstation_cidr_blocks" {
  description = "List of CIDR blocks for workstation access"
  type        = list(string)
  default     = []
}

variable "node_groups" {
  description = "Map of EKS managed node group definitions to create"
  type = map(object({
    capacity_type               = string
    instance_types              = list(string)
    ami_type                    = string
    disk_size                   = number
    desired_size                = number
    max_size                    = number
    min_size                    = number
    max_unavailable_percentage  = number
    labels                      = map(string)
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
    launch_template = object({
      id      = string
      version = string
    })
    remote_access = object({
      ec2_ssh_key               = string
      source_security_group_ids = list(string)
    })
  }))
  default = {
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
}

variable "cluster_addons" {
  description = "Map of cluster addon configurations to enable for the cluster"
  type = map(object({
    addon_version            = string
    resolve_conflicts        = string
    service_account_role_arn = string
  }))
  default = {
    coredns = {
      addon_version            = "v1.11.3-eksbuild.1"
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = ""
    }
    kube-proxy = {
      addon_version            = "v1.31.0-eksbuild.3"
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = ""
    }
    vpc-cni = {
      addon_version            = "v1.18.5-eksbuild.1"
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = ""
    }
  }
}

variable "create_kms_key" {
  description = "Controls if a KMS key for cluster encryption should be created"
  type        = bool
  default     = true
}

# ALB Variables
variable "alb_internal" {
  description = "If true, the LB will be internal"
  type        = bool
  default     = false
}

variable "alb_enable_deletion_protection" {
  description = "If true, deletion of the load balancer will be disabled via the AWS API"
  type        = bool
  default     = false
}

variable "alb_enable_cross_zone_load_balancing" {
  description = "If true, cross-zone load balancing of the load balancer will be enabled"
  type        = bool
  default     = true
}

variable "alb_enable_http2" {
  description = "Indicates whether HTTP/2 is enabled in application load balancers"
  type        = bool
  default     = true
}

variable "alb_idle_timeout" {
  description = "The time in seconds that the connection is allowed to be idle"
  type        = number
  default     = 60
}

variable "alb_access_logs_enabled" {
  description = "A boolean flag to enable/disable access_logs"
  type        = bool
  default     = false
}

variable "alb_access_logs_bucket" {
  description = "The S3 bucket name to store the logs in"
  type        = string
  default     = ""
}

variable "alb_access_logs_prefix" {
  description = "The S3 bucket prefix"
  type        = string
  default     = "alb-logs"
}

variable "alb_ingress_rules" {
  description = "List of ingress rules for ALB security group"
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
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
}

variable "alb_enable_http_listener" {
  description = "Controls if HTTP listener should be created"
  type        = bool
  default     = true
}

variable "alb_enable_https_listener" {
  description = "Controls if HTTPS listener should be created"
  type        = bool
  default     = true
}

variable "alb_ssl_policy" {
  description = "Name of the SSL Policy for the listener"
  type        = string
  default     = "ELBSecurityPolicy-TLS-1-2-2017-01"
}

# Regional S3 Variables
variable "regional_s3_buckets" {
  description = "Map of regional S3 buckets to create"
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
    regional-artifacts = {
      purpose                      = "Regional artifacts and logs"
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