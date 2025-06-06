# Application Load Balancer (ALB)
resource "aws_lb" "main" {
  name               = "${var.project}-alb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.aws_subnet_ids.public.ids

  enable_deletion_protection = false

  tags = merge(local.tags, {
    Name = "${var.project}-alb-${var.environment}"
  })
}

# Target group pour le frontend
resource "aws_lb_target_group" "frontend" {
  name     = "${var.project}-frontend-tg-${var.environment}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.existing.id

  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    matcher             = "200"
  }

  tags = merge(local.tags, {
    Name = "${var.project}-frontend-tg-${var.environment}"
  })
}

# Target group pour le backend
resource "aws_lb_target_group" "backend" {
  name     = "${var.project}-backend-tg-${var.environment}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.existing.id

  health_check {
    enabled             = true
    interval            = 30
    path                = "/api/health"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    matcher             = "200"
  }

  tags = merge(local.tags, {
    Name = "${var.project}-backend-tg-${var.environment}"
  })
}

# Listener HTTP qui redirige vers HTTPS
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# Listener HTTPS
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

# Règle pour router les requêtes API vers le backend
resource "aws_lb_listener_rule" "api" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

# Certificat auto-signé pour le développement
resource "tls_private_key" "cert" {
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "cert" {
  private_key_pem = tls_private_key.cert.private_key_pem

  subject {
    common_name  = "${var.project}.example.com"
    organization = "Example, Inc"
  }

  validity_period_hours = 8760 # 1 an

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "aws_acm_certificate" "cert" {
  private_key      = tls_private_key.cert.private_key_pem
  certificate_body = tls_self_signed_cert.cert.cert_pem

  tags = merge(local.tags, {
    Name = "${var.project}-cert-${var.environment}"
  })
}