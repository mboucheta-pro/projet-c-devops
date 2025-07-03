# DevOps Infrastructure Load Balancer
resource "aws_lb" "devops" {
  name               = "${var.project}-devops-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  tags = merge(local.tags, {
    Purpose = "DevOps-Infrastructure"
  })
}

# Target Groups
resource "aws_lb_target_group" "jenkins" {
  name     = "${var.project}-jenkins-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.projet-c.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/login"
    matcher             = "200"
  }

  tags = merge(local.tags, {
    Purpose = "DevOps-Infrastructure"
  })
}

resource "aws_lb_target_group" "sonarqube" {
  name     = "${var.project}-sonarqube-tg"
  port     = 9000
  protocol = "HTTP"
  vpc_id   = aws_vpc.projet-c.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    matcher             = "200"
  }

  tags = merge(local.tags, {
    Purpose = "DevOps-Infrastructure"
  })
}

resource "aws_lb_target_group" "monitoring" {
  name     = "${var.project}-monitoring-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.projet-c.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/api/health"
    matcher             = "200"
  }

  tags = merge(local.tags, {
    Purpose = "DevOps-Infrastructure"
  })
}

# Target Group Attachments
resource "aws_lb_target_group_attachment" "jenkins" {
  target_group_arn = aws_lb_target_group.jenkins.arn
  target_id        = aws_instance.jenkins.id
  port             = 8080
}

resource "aws_lb_target_group_attachment" "sonarqube" {
  target_group_arn = aws_lb_target_group.sonarqube.arn
  target_id        = aws_instance.sonarqube.id
  port             = 9000
}

resource "aws_lb_target_group_attachment" "monitoring" {
  target_group_arn = aws_lb_target_group.monitoring.arn
  target_id        = aws_instance.monitoring.id
  port             = 3000
}

# Listeners
resource "aws_lb_listener" "jenkins" {
  load_balancer_arn = aws_lb.devops.arn
  port              = "8080"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jenkins.arn
  }
}

resource "aws_lb_listener" "sonarqube" {
  load_balancer_arn = aws_lb.devops.arn
  port              = "9000"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sonarqube.arn
  }
}

resource "aws_lb_listener" "monitoring" {
  load_balancer_arn = aws_lb.devops.arn
  port              = "3000"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.monitoring.arn
  }
}