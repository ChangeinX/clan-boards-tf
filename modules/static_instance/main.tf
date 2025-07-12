
data "aws_ssm_parameter" "al2023_arm" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-minimal-kernel-6.1-arm64"
}

data "aws_ami" "al2023_arm" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "image-id"
    values = [data.aws_ssm_parameter.al2023_arm.value]
  }
}

resource "aws_security_group" "this" {
  name        = "${var.app_name}-static-sg"
  description = "Allow outbound to CoC API and database"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ip]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.rds_sg_id]
  }
}

resource "aws_instance" "this" {
  ami                         = data.aws_ami.al2023_arm.id
  instance_type               = "t4g.micro"
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.this.id]
  associate_public_ip_address = true

  user_data = <<-EOT
              #!/bin/bash
              yum update -y
              amazon-linux-extras install docker -y
              service docker start
              docker run -d --restart=always \
                -e COC_API_TOKEN=${var.coc_api_token} \
                -e DATABASE_URL=postgresql+psycopg://postgres:${var.db_password}@${var.db_endpoint}:5432/postgres \
                ${var.image}
              EOT
}

resource "aws_eip" "this" {
  instance = aws_instance.this.id
  domain   = "vpc"
}

