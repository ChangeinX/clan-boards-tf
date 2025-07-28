resource "aws_security_group" "alb" {
  name        = "${var.app_name}-alb-sg"
  description = "Allow HTTP/HTTPS inbound"
  vpc_id      = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "this" {
  name               = "${var.app_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids
}

resource "aws_lb_target_group" "app" {
  name_prefix = "${substr(var.app_name, 0, 2)}app-"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  lifecycle {
    create_before_destroy = true
  }

  health_check {
    path = "/"
  }
}

resource "aws_lb_target_group" "api" {
  name_prefix = "${substr(var.app_name, 0, 2)}api-"
  port        = 8001
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  lifecycle {
    create_before_destroy = true
  }

  health_check {
    path                = "/api/v1/health"
    interval            = 30
    timeout             = 20
    healthy_threshold   = 5
    unhealthy_threshold = 10
    matcher             = "200-399"
  }
}

resource "aws_lb_target_group" "messages" {
  name_prefix = "${substr(var.app_name, 0, 2)}msg-"
  port        = 8010
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  lifecycle {
    create_before_destroy = true
  }

  health_check {
    path                = "/api/v1/health"
    interval            = 30
    timeout             = 20
    healthy_threshold   = 5
    unhealthy_threshold = 10
    matcher             = "200-399"
  }
}

resource "aws_lb_target_group" "user" {
  name_prefix = "${substr(var.app_name, 0, 2)}usr-"
  port        = 8020
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  lifecycle {
    create_before_destroy = true
  }

  health_check {
    path                = "/api/v1/health"
    interval            = 30
    timeout             = 20
    healthy_threshold   = 5
    unhealthy_threshold = 10
    matcher             = "200-399"
  }
}

resource "aws_lb_target_group" "notifications" {
  name_prefix = "${substr(var.app_name, 0, 2)}ntf-"
  port        = 8030
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  lifecycle {
    create_before_destroy = true
  }

  health_check {
    path                = "/api/v1/health"
    interval            = 180
    timeout             = 120
    healthy_threshold   = 5
    unhealthy_threshold = 10
    matcher             = "200-399"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
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

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_lb_listener_rule" "messages" {
  count        = var.api_host == null ? 0 : 1
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.messages.arn
  }

  condition {
    host_header {
      values = [var.api_host]
    }
  }

  condition {
    path_pattern {
      values = ["/api/v1/chat*"]
    }
  }
}

resource "aws_lb_listener_rule" "user" {
  count        = var.api_host == null ? 0 : 1
  listener_arn = aws_lb_listener.https.arn
  priority     = 105

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.user.arn
  }

  condition {
    host_header {
      values = [var.api_host]
    }
  }

  condition {
    path_pattern {
      values = ["/api/v1/friends*"]
    }
  }
}

resource "aws_lb_listener_rule" "api" {
  count        = var.api_host == null ? 0 : 1
  listener_arn = aws_lb_listener.https.arn
  priority     = 500

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }

  condition {
    host_header {
      values = [var.api_host]
    }
  }

  condition {
    path_pattern {
      values = ["/api/v1*"]
    }
  }
}

resource "aws_lb_listener_rule" "notifications" {
  count        = var.api_host == null ? 0 : 1
  listener_arn = aws_lb_listener.https.arn
  priority     = 110

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.notifications.arn
  }

  condition {
    host_header {
      values = [var.api_host]
    }
  }

  condition {
    path_pattern {
      values = ["/api/v1/notifications*"]
    }
  }
}

resource "aws_wafv2_web_acl_association" "this" {
  resource_arn = aws_lb.this.arn
  web_acl_arn  = var.waf_web_acl_arn
}

