# -----------------------------
# Auto Scaling Group
# -----------------------------

resource "aws_autoscaling_group" "web" {
  name = "auto-healing-web-asg"

  min_size         = 2
  max_size         = 3
  desired_capacity = 2

  vpc_zone_identifier = [
    aws_subnet.public_1.id,
    aws_subnet.public_2.id
  ]

  health_check_type         = "ELB"
  health_check_grace_period = 180

  target_group_arns = [
    aws_lb_target_group.web.arn
  ]

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "auto-healing-web"
    propagate_at_launch = true
  }
}
