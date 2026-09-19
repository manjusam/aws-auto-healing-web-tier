# -----------------------------
# Amazon Linux 2023 AMI
# -----------------------------

data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}


# -----------------------------
# EC2 Launch Template
# -----------------------------

resource "aws_launch_template" "web" {
  name = "auto-healing-web-lt"

  image_id      = data.aws_ssm_parameter.al2023_ami.value
  instance_type = var.instance_type

  vpc_security_group_ids = [
    aws_security_group.ec2.id
  ]

  user_data = base64encode(<<-EOF
  #!/bin/bash

  dnf update -y
  dnf install -y docker

  systemctl enable docker
  systemctl start docker

  docker pull ghcr.io/manjusam/auto-healing-web:latest

  docker run -d \
    --restart unless-stopped \
    --name auto-healing-web \
    -p 80:80 \
    ghcr.io/manjusam/auto-healing-web:latest
EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "auto-healing-web"
    }
  }
}