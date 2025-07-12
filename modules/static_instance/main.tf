
data "aws_ami" "al2023_arm" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-minimal-arm64-*"]
  }
}

resource "aws_security_group" "this" {
  name        = "${var.app_name}-static-sg"
  description = "Allow outbound to CoC API and database"
  vpc_id      = var.vpc_id

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
                -e DATABASE_URL=postgres://postgres:${var.db_password}@${var.db_endpoint}:5432/postgres \
                ${var.image}
              EOT
}

resource "aws_eip" "this" {
  instance = aws_instance.this.id
  vpc      = true
}

