resource "aws_iam_role" "this" {
  name = "${var.app_name}-refresh-worker-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "this" {
  name = "${var.app_name}-refresh-worker-policy"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          var.database_url_arn,
          var.redis_url_arn,
          var.coc_email_arn,
          var.coc_password_arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "vpc_access" {
  count      = var.vpc_config_enabled ? 1 : 0
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_security_group" "this" {
  count  = var.vpc_config_enabled ? 1 : 0
  name   = "${var.app_name}-refresh-worker-sg"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lambda_function" "this" {
  function_name = "${var.app_name}-refresh-worker"
  s3_bucket     = var.lambda_artifacts_bucket
  s3_key        = var.lambda_s3_key
  role          = aws_iam_role.this.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"
  timeout       = 300
  memory_size   = 512

  environment {
    variables = {
      DATABASE_URL_SECRET = replace(var.database_url_arn, "arn:aws:secretsmanager:", "")
      REDIS_URL_SECRET    = replace(var.redis_url_arn, "arn:aws:secretsmanager:", "")
      COC_EMAIL_SECRET    = replace(var.coc_email_arn, "arn:aws:secretsmanager:", "")
      COC_PASSWORD_SECRET = replace(var.coc_password_arn, "arn:aws:secretsmanager:", "")
      ENVIRONMENT         = var.app_env
      LOG_LEVEL           = "INFO"
      PYTHONPATH          = "/var/task:/opt/python"
    }
  }

  dynamic "vpc_config" {
    for_each = var.vpc_config_enabled ? [1] : []
    content {
      subnet_ids         = var.lambda_subnet_ids
      security_group_ids = [aws_security_group.this[0].id]
    }
  }

  depends_on = [
    aws_iam_role_policy.this,
    aws_cloudwatch_log_group.this,
  ]
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.app_name}-refresh-worker"
  retention_in_days = var.log_retention_days
}