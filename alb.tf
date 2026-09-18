# -----------------------------
# Application Load Balancer Target Group
# -----------------------------

resource "aws_lb_target_group" "web" {
  name     = "auto-healing-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
  }

  tags = {
    Name = "auto-healing-web-tg"
  }
}

# -----------------------------
# Application Load Balancer
# -----------------------------

resource "aws_lb" "web" {
  name               = "auto-healing-web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets = [
    aws_subnet.public_1.id,
    aws_subnet.public_2.id
  ]

  tags = {
    Name = "auto-healing-web-alb"
  }
}

# -----------------------------
# ALB Listener
# -----------------------------

resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}