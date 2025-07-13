resource "aws_security_group" "nat" {
  name   = "${var.app_name}-nat-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ip]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*arm64*"]
  }
}

resource "aws_instance" "this" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = "t4g.nano"
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.nat.id]
  key_name                    = var.key_name
  associate_public_ip_address = true
  source_dest_check           = false
  user_data                   = <<-EOT
    #!/bin/bash -xe
    yum install -y iptables-services
    echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.d/99-nat.conf
    sysctl --system
    IF=$(ip route show default | awk '{print $5}')
    iptables -t nat -A POSTROUTING -o "$IF" -j MASQUERADE
    service iptables save
    systemctl enable --now iptables
    EOT
  user_data_replace_on_change = true
  tags = {
    Name = "${var.app_name}-nat"
  }
}

resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { Name = "${var.app_name}-nat-eip" }
}

resource "aws_eip_association" "nat" {
  allocation_id = aws_eip.nat.id
  instance_id   = aws_instance.this.id
}

resource "aws_route" "private_to_nat" {
  route_table_id         = var.private_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_instance.this.primary_network_interface_id
}

