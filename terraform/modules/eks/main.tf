# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = "${var.project_name}-${var.environment}"
  role_arn = var.cluster_service_role_arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = concat(var.private_subnet_ids, var.public_subnet_ids)
    endpoint_private_access = var.cluster_endpoint_private_access
    endpoint_public_access  = var.cluster_endpoint_public_access
    public_access_cidrs     = var.cluster_endpoint_public_access_cidrs
    security_group_ids      = [var.cluster_security_group_id]
  }

  dynamic "encryption_config" {
    for_each = var.create_kms_key || (var.kms_key_arn != null && var.kms_key_arn != "") ? [1] : []
    content {
      provider {
        key_arn = var.create_kms_key ? aws_kms_key.eks[0].arn : var.kms_key_arn
      }
      resources = ["secrets"]
    }
  }

  enabled_cluster_log_types = var.cluster_enabled_log_types

  depends_on = [
    aws_cloudwatch_log_group.eks_cluster,
    aws_kms_key.eks
  ]

  tags = var.tags
}

# CloudWatch Log Group for EKS Cluster
resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/${var.project_name}-${var.environment}/cluster"
  retention_in_days = var.cloudwatch_log_group_retention_in_days

  tags = var.tags
}

# EKS OIDC Identity Provider
data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer

  tags = merge(var.tags, {
    Name = "${var.project_name}-eks-irsa-${var.environment}"
  })
}

# EKS Managed Node Groups
resource "aws_eks_node_group" "main" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-${each.key}-${var.environment}"
  node_role_arn   = var.node_group_role_arn
  subnet_ids      = var.private_subnet_ids

  # Instance configuration
  capacity_type  = each.value.capacity_type
  instance_types = each.value.instance_types
  ami_type       = each.value.ami_type
  disk_size      = each.value.disk_size

  # Scaling configuration
  scaling_config {
    desired_size = each.value.desired_size
    max_size     = each.value.max_size
    min_size     = each.value.min_size
  }

  # Update configuration
  update_config {
    max_unavailable_percentage = each.value.max_unavailable_percentage
  }

  # Launch template
  dynamic "launch_template" {
    for_each = each.value.launch_template != null ? [each.value.launch_template] : []
    content {
      id      = launch_template.value.id
      version = launch_template.value.version
    }
  }

  # Remote access
  dynamic "remote_access" {
    for_each = each.value.remote_access != null ? [each.value.remote_access] : []
    content {
      ec2_ssh_key               = remote_access.value.ec2_ssh_key
      source_security_group_ids = remote_access.value.source_security_group_ids
    }
  }

  # Taints
  dynamic "taint" {
    for_each = each.value.taints != null ? each.value.taints : []
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  # Labels
  labels = merge(
    {
      "node-group" = each.key
      "environment" = var.environment
    },
    each.value.labels
  )

  tags = merge(var.tags, {
    Name = "${var.project_name}-${each.key}-${var.environment}"
  })

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  depends_on = [aws_eks_cluster.main]

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

# EKS Add-ons
resource "aws_eks_addon" "main" {
  for_each = var.cluster_addons

  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = each.key
  addon_version               = each.value.addon_version != "" ? each.value.addon_version : null
  resolve_conflicts_on_create = each.value.resolve_conflicts
  resolve_conflicts_on_update = each.value.resolve_conflicts
  service_account_role_arn    = each.value.service_account_role_arn != "" ? each.value.service_account_role_arn : null

  tags = var.tags

  depends_on = [aws_eks_node_group.main]
}

# Security Group Rules for Additional Access
resource "aws_security_group_rule" "cluster_ingress_workstation_https" {
  count = length(var.workstation_cidr_blocks) > 0 ? 1 : 0

  description       = "Allow workstation to communicate with the cluster API Server"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.workstation_cidr_blocks
  security_group_id = var.cluster_security_group_id
}

# KMS Key for EKS
resource "aws_kms_key" "eks" {
  count = var.create_kms_key ? 1 : 0

  description             = "KMS key for EKS cluster ${var.project_name}-${var.environment}"
  deletion_window_in_days = var.kms_key_deletion_window_in_days
  enable_key_rotation     = var.kms_key_enable_key_rotation

  tags = merge(var.tags, {
    Name = "${var.project_name}-eks-kms-${var.environment}"
  })
}

resource "aws_kms_alias" "eks" {
  count = var.create_kms_key ? 1 : 0

  name          = "alias/${var.project_name}-eks-${var.environment}"
  target_key_id = aws_kms_key.eks[0].key_id
}