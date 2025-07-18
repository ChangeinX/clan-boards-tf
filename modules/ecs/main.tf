

resource "aws_security_group" "ecs" {
  name        = "${var.app_name}-ecs-sg"
  description = "Allow ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = 3000
    to_port         = 3000
    security_groups = [var.alb_sg_id]
  }

  # allow traffic from the ALB to the worker service
  ingress {
    protocol        = "tcp"
    from_port       = 8001
    to_port         = 8001
    security_groups = [var.alb_sg_id]
  }

  # allow traffic from the ALB to the messages service
  ingress {
    protocol        = "tcp"
    from_port       = 8010
    to_port         = 8010
    security_groups = [var.alb_sg_id]
  }

  # allow internal access to the static service
  ingress {
    protocol  = "tcp"
    from_port = 8000
    to_port   = 8000
    self      = true
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Log groups
resource "aws_cloudwatch_log_group" "worker" {
  name = "/ecs/${var.app_name}-worker"
}

resource "aws_cloudwatch_log_group" "static" {
  name = "/ecs/${var.app_name}-static"
}

resource "aws_cloudwatch_log_group" "messages" {
  name = "/ecs/${var.app_name}-messages"
}

# IAM roles
resource "aws_iam_role" "task_execution" {
  name = "${var.app_name}-task-exec"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "task_exec_policy" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "task_with_db" {
  name = "${var.app_name}-task-db"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "task_db_policy" {
  role       = aws_iam_role.task_with_db.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
}

resource "aws_iam_role_policy" "messages_table" {
  name = "${var.app_name}-messages-table"
  role = aws_iam_role.task_with_db.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["dynamodb:PutItem"],
      Resource = var.messages_table_arn
    }]
  })
}

resource "aws_iam_policy" "event_publish" {
  name   = "ChatEventPublish"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "appsync:EventPublish"
      Resource = "${var.event_api_arn}/*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "attach_event_publish" {
  role       = aws_iam_role.task_with_db.name
  policy_arn = aws_iam_policy.event_publish.arn
}

# Secrets
resource "aws_secretsmanager_secret" "app_env" {
  name = "${var.app_name}-app-env"
}

resource "aws_secretsmanager_secret_version" "app_env" {
  secret_id     = aws_secretsmanager_secret.app_env.id
  secret_string = var.app_env
}


resource "random_password" "secret_key" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "secret_key" {
  name = "${var.app_name}-secret-key"
}

resource "aws_secretsmanager_secret_version" "secret_key" {
  secret_id     = aws_secretsmanager_secret.secret_key.id
  secret_string = random_password.secret_key.result
}

resource "aws_secretsmanager_secret" "database_url" {
  name = "${var.app_name}-db-url"
}

resource "aws_secretsmanager_secret_version" "database_url" {
  secret_id     = aws_secretsmanager_secret.database_url.id
  secret_string = "postgresql+psycopg://postgres:${var.db_password}@${var.db_endpoint}:5432/postgres"
}

resource "aws_secretsmanager_secret" "coc_api_token" {
  name = "${var.app_name}-coc-token"
}

resource "aws_secretsmanager_secret_version" "coc_api_token" {
  secret_id     = aws_secretsmanager_secret.coc_api_token.id
  secret_string = var.coc_api_token
}


resource "aws_secretsmanager_secret" "aws_region" {
  name = "${var.app_name}-aws-region"
}

resource "aws_secretsmanager_secret_version" "aws_region" {
  secret_id     = aws_secretsmanager_secret.aws_region.id
  secret_string = var.region
}

resource "aws_secretsmanager_secret" "messages_table" {
  name = "${var.app_name}-messages-table"
}

resource "aws_secretsmanager_secret_version" "messages_table" {
  secret_id     = aws_secretsmanager_secret.messages_table.id
  secret_string = var.messages_table
}

resource "aws_secretsmanager_secret" "appsync_events_url" {
  name = "${var.app_name}-appsync-events-url"
}

resource "aws_secretsmanager_secret_version" "appsync_events_url" {
  secret_id     = aws_secretsmanager_secret.appsync_events_url.id
  secret_string = var.appsync_events_url
}


resource "aws_secretsmanager_secret" "google_client_id" {
  name = "${var.app_name}-google-client-id"
}

resource "aws_secretsmanager_secret_version" "google_client_id" {
  secret_id     = aws_secretsmanager_secret.google_client_id.id
  secret_string = var.google_client_id
}

resource "aws_secretsmanager_secret" "google_client_secret" {
  name = "${var.app_name}-google-client-secret"
}

resource "aws_secretsmanager_secret_version" "google_client_secret" {
  secret_id     = aws_secretsmanager_secret.google_client_secret.id
  secret_string = var.google_client_secret
}

resource "aws_iam_role_policy" "execution_secrets" {
  name = "${var.app_name}-execution-secrets"
  role = aws_iam_role.task_execution.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = ["secretsmanager:GetSecretValue"],
      Resource = [
        aws_secretsmanager_secret.app_env.arn,
        aws_secretsmanager_secret.database_url.arn,
        aws_secretsmanager_secret.secret_key.arn,
        aws_secretsmanager_secret.aws_region.arn,
        aws_secretsmanager_secret.messages_table.arn,
        aws_secretsmanager_secret.appsync_events_url.arn,
        aws_secretsmanager_secret.coc_api_token.arn,
        aws_secretsmanager_secret.google_client_id.arn,
        aws_secretsmanager_secret.google_client_secret.arn
      ]
    }]
  })
}

# ECS cluster
resource "aws_ecs_cluster" "this" {
  name = "${var.app_name}-cluster"
}

# Cloud Map namespace for service discovery
resource "aws_service_discovery_private_dns_namespace" "this" {
  name = "${var.app_name}.local"
  vpc  = var.vpc_id
}

resource "aws_service_discovery_service" "static" {
  name = "static"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.this.id
    dns_records {
      ttl  = 10
      type = "A"
    }
    routing_policy = "WEIGHTED"
  }
  health_check_custom_config {
    failure_threshold = 1
  }
}

# Task definition

resource "aws_ecs_task_definition" "worker" {
  family                   = "${var.app_name}-worker"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  runtime_platform {
    cpu_architecture        = "ARM64"
    operating_system_family = "LINUX"
  }

  execution_role_arn = aws_iam_role.task_execution.arn
  task_role_arn      = aws_iam_role.task_with_db.arn

  container_definitions = jsonencode([
    {
      name      = "worker"
      image     = var.worker_image
      essential = true
      portMappings = [
        {
          containerPort = 8001
          hostPort      = 8001
        }
      ]
      environment = [
        {
          name  = "PORT"
          value = "8001"
        },
        {
          name  = "SYNC_BASE"
          value = var.sync_base
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.worker.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "worker"
        }
      }
      secrets = [
        {
          name      = "APP_ENV"
          valueFrom = aws_secretsmanager_secret.app_env.arn
        },
        {
          name      = "DATABASE_URL"
          valueFrom = aws_secretsmanager_secret.database_url.arn
        },
        {
          name      = "SECRET_KEY"
          valueFrom = aws_secretsmanager_secret.secret_key.arn
        },
        {
          name      = "COC_API_TOKEN"
          valueFrom = aws_secretsmanager_secret.coc_api_token.arn
        },
        {
          name      = "GOOGLE_CLIENT_ID"
          valueFrom = aws_secretsmanager_secret.google_client_id.arn
        },
        {
          name      = "GOOGLE_CLIENT_SECRET"
          valueFrom = aws_secretsmanager_secret.google_client_secret.arn
        }
      ]
    }
  ])

  lifecycle {
    ignore_changes = [container_definitions]
  }
}

# Task definition for the static sync service
resource "aws_ecs_task_definition" "static" {
  family                   = "${var.app_name}-static"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  runtime_platform {
    cpu_architecture        = "ARM64"
    operating_system_family = "LINUX"
  }

  execution_role_arn = aws_iam_role.task_execution.arn
  task_role_arn      = aws_iam_role.task_with_db.arn

  container_definitions = jsonencode([
    {
      name      = "static"
      image     = var.static_ip_image
      essential = true
      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
        }
      ]
      environment = [
        {
          name  = "PORT"
          value = "8000"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.static.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "static"
        }
      }
      secrets = [
        {
          name      = "COC_API_TOKEN"
          valueFrom = aws_secretsmanager_secret.coc_api_token.arn
        },
        {
          name      = "DATABASE_URL"
          valueFrom = aws_secretsmanager_secret.database_url.arn
        },
        {
          name      = "GOOGLE_CLIENT_ID"
          valueFrom = aws_secretsmanager_secret.google_client_id.arn
        },
        {
          name      = "GOOGLE_CLIENT_SECRET"
          valueFrom = aws_secretsmanager_secret.google_client_secret.arn
        }
      ]
    }
  ])

  lifecycle {
    ignore_changes = [container_definitions]
  }
}

resource "aws_ecs_task_definition" "messages" {
  family                   = "${var.app_name}-messages"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  runtime_platform {
    cpu_architecture        = "ARM64"
    operating_system_family = "LINUX"
  }

  execution_role_arn = aws_iam_role.task_execution.arn
  task_role_arn      = aws_iam_role.task_with_db.arn

  container_definitions = jsonencode([
    {
      name      = "messages"
      image     = var.messages_image
      essential = true
      portMappings = [
        {
          containerPort = 8010
          hostPort      = 8010
        }
      ]
      environment = [
        {
          name  = "PORT"
          value = "8010"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.messages.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "messages"
        }
      }
      secrets = [
        {
          name      = "APP_ENV"
          valueFrom = aws_secretsmanager_secret.app_env.arn
        },
        {
          name      = "DATABASE_URL"
          valueFrom = aws_secretsmanager_secret.database_url.arn
        },
        {
          name      = "SECRET_KEY"
          valueFrom = aws_secretsmanager_secret.secret_key.arn
        },
        {
          name      = "AWS_REGION"
          valueFrom = aws_secretsmanager_secret.aws_region.arn
        },
        {
          name      = "MESSAGES_TABLE"
          valueFrom = aws_secretsmanager_secret.messages_table.arn
        },
        {
          name      = "APPSYNC_EVENTS_URL"
          valueFrom = aws_secretsmanager_secret.appsync_events_url.arn
        },
        {
          name      = "GOOGLE_CLIENT_ID"
          valueFrom = aws_secretsmanager_secret.google_client_id.arn
        },
        {
          name      = "GOOGLE_CLIENT_SECRET"
          valueFrom = aws_secretsmanager_secret.google_client_secret.arn
        }
      ]
    }
  ])

  lifecycle {
    ignore_changes = [container_definitions]
  }
}


resource "aws_ecs_service" "worker" {
  name            = "${var.app_name}-worker-svc"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.worker.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = var.worker_target_group_arn
    container_name   = "worker"
    container_port   = 8001
  }
  depends_on = [var.listener_arn]

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  lifecycle {
    ignore_changes = [task_definition]
  }
}

# Service running the static sync container
resource "aws_ecs_service" "static" {
  name            = "${var.app_name}-static-svc"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.static.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }
  service_registries {
    registry_arn = aws_service_discovery_service.static.arn
  }

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  lifecycle {
    ignore_changes = [task_definition]
  }
}

resource "aws_ecs_service" "messages" {
  name            = "${var.app_name}-messages-svc"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.messages.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = var.messages_target_group_arn
    container_name   = "messages"
    container_port   = 8010
  }
  depends_on = [var.listener_arn]

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  lifecycle {
    ignore_changes = [task_definition]
  }
}
