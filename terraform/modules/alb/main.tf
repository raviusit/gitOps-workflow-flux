# Application Load Balancer for EKS
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb-${var.environment}"
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.internal ? var.private_subnet_ids : var.public_subnet_ids

  enable_deletion_protection       = var.enable_deletion_protection
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing
  enable_http2                     = var.enable_http2
  idle_timeout                     = var.idle_timeout

  dynamic "access_logs" {
    for_each = var.access_logs_enabled ? [1] : []
    content {
      bucket  = var.access_logs_bucket
      prefix  = var.access_logs_prefix
      enabled = var.access_logs_enabled
    }
    }

  tags = merge(var.tags, {
    Name = "${var.project_name}-alb-${var.environment}"
    Type = var.internal ? "internal" : "internet-facing"
  })
}

# Security Group for ALB
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg-${var.environment}"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-alb-sg-${var.environment}"
  })
}

# Target Group for health checks
resource "aws_lb_target_group" "health" {
  name     = "${var.project_name}-health-${var.environment}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = var.health_check_healthy_threshold
    interval            = var.health_check_interval
    matcher             = var.health_check_matcher
    path                = var.health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = var.health_check_timeout
    unhealthy_threshold = var.health_check_unhealthy_threshold
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-health-tg-${var.environment}"
  })
}

# HTTP Listener
resource "aws_lb_listener" "http" {
  count = var.enable_http_listener ? 1 : 0

  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  # Redirect to HTTPS if certificate exists, otherwise forward to target group
  dynamic "default_action" {
    for_each = var.enable_https_listener && var.certificate_arn != null && var.certificate_arn != "" ? [1] : []
    content {
      type = "redirect"
      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  dynamic "default_action" {
    for_each = var.enable_https_listener && var.certificate_arn != null && var.certificate_arn != "" ? [] : [1]
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.health.arn
    }
  }

  tags = var.tags
}

# HTTPS Listener
resource "aws_lb_listener" "https" {
  count = var.enable_https_listener ? 1 : 0

  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.health.arn
  }

  tags = var.tags
}

# Listener Rules for routing
resource "aws_lb_listener_rule" "host_based_routing" {
  for_each = var.listener_rules

  listener_arn = var.enable_https_listener ? aws_lb_listener.https[0].arn : aws_lb_listener.http[0].arn
  priority     = each.value.priority

  action {
    type             = "forward"
    target_group_arn = each.value.target_group_arn
  }

  condition {
    host_header {
      values = each.value.host_header_values
    }
  }

  tags = var.tags
}

# WAF Web ACL Association
resource "aws_wafv2_web_acl_association" "main" {
  count = var.waf_web_acl_arn != "" ? 1 : 0

  resource_arn = aws_lb.main.arn
  web_acl_arn  = var.waf_web_acl_arn
}