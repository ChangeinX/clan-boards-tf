resource "aws_security_group" "rds" {
  name        = "${var.app_name}-rds-sg"
  description = "Allow RDS access from ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 5432
    cidr_blocks = [var.vpc_cidr]
    to_port     = 5432
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "remote" {
  name        = "${var.app_name}-rds-remote-sg"
  description = "Allow remote access to RDS"
  vpc_id      = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 5432
    to_port     = 5432
    cidr_blocks = [var.allowed_ip]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "postgres" {
  name       = "${var.app_name}-db-subnet"
  subnet_ids = var.private_subnet_ids

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_instance" "postgres" {
  identifier             = "${var.app_name}-db"
  engine                 = "postgres"
  instance_class         = "db.t3.micro"
  username               = "postgres"
  password               = var.db_password
  allocated_storage      = 20
  db_subnet_group_name   = aws_db_subnet_group.postgres.name
  vpc_security_group_ids = [aws_security_group.rds.id, aws_security_group.remote.id]
  publicly_accessible    = true
  deletion_protection    = true
  skip_final_snapshot    = false
}
