resource "aws_dynamodb_table" "chat_history" {
  name         = "${var.app_name}-chat-history"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "groupId"
  range_key    = "timestamp"

  attribute {
    name = "groupId"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  ttl {
    attribute_name = "expiresAt"
    enabled        = true
  }
}

resource "aws_iam_role" "appsync_exec" {
  name = "${var.app_name}-appsync-exec"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Action    = "sts:AssumeRole",
      Principal = { Service = "appsync.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "dynamodb_put" {
  name = "${var.app_name}-chat-put"
  role = aws_iam_role.appsync_exec.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["dynamodb:PutItem"],
      Resource = aws_dynamodb_table.chat_history.arn
    }]
  })
}

resource "aws_appsync_event_api" "chat" {
  name               = "${var.app_name}-chat-api"
  authentication_type = "OPENID_CONNECT"

  openid_connect_config {
    issuer    = "https://accounts.google.com"
    client_id = var.google_oauth_web_client_id
    auth_ttl  = 3600
    iat_ttl   = 3600
  }

  additional_authentication_provider {
    authentication_type = "AWS_IAM"
  }

  channel_namespace {
    name        = "/groups/{groupId}"
    data_source = aws_appsync_datasource.chat_history.name
  }

  channel_namespace {
    name        = "/global"
    data_source = aws_appsync_datasource.chat_history.name
  }
}

resource "aws_appsync_datasource" "chat_history" {
  api_id           = aws_appsync_event_api.chat.id
  name             = "ChatHistory"
  type             = "AMAZON_DYNAMODB"
  service_role_arn = aws_iam_role.appsync_exec.arn

  dynamodb_config {
    table_name = aws_dynamodb_table.chat_history.name
    aws_region = var.region
  }
}

resource "aws_iam_role_policy" "ecs_publish" {
  name = "${var.app_name}-chat-publish"
  role = var.ecs_task_role_arn
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["appsync:GraphQL"],
      Resource = aws_appsync_event_api.chat.arn,
      Condition = {
        IpAddress = { "aws:VpcSourceIp" = var.vpc_cidr }
      }
    }]
  })
}

resource "aws_ssm_parameter" "api_url_wss" {
  name  = "/app/chat/api_url_wss"
  type  = "String"
  value = aws_appsync_event_api.chat.uris["real_time_url"]
}

resource "aws_ssm_parameter" "api_url_https" {
  name  = "/app/chat/api_url_https"
  type  = "String"
  value = aws_appsync_event_api.chat.uris["graphql_url"]
}

resource "aws_ssm_parameter" "api_region" {
  name  = "/app/chat/region"
  type  = "String"
  value = var.region
}

resource "aws_ssm_parameter" "table_name" {
  name  = "/app/chat/dynamodb_table"
  type  = "String"
  value = aws_dynamodb_table.chat_history.name
}

