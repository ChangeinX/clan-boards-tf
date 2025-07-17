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

data "template_file" "event_api" {
  template = file("${path.module}/event_api.yaml.tpl")
  vars = {
    api_name     = "${var.app_name}-chat-api"
    client_id    = var.google_oauth_web_client_id
    table_name   = aws_dynamodb_table.chat_history.name
    service_role = aws_iam_role.appsync_exec.arn
    region       = var.region
  }
}

resource "aws_cloudformation_stack" "chat_api" {
  name          = "${var.app_name}-chat-api"
  template_body = data.template_file.event_api.rendered
}

resource "aws_appsync_datasource" "chat_history" {
  api_id           = aws_cloudformation_stack.chat_api.outputs["ApiId"]
  name             = "ChatHistory"
  type             = "AMAZON_DYNAMODB"
  service_role_arn = aws_iam_role.appsync_exec.arn

  dynamodb_config {
    table_name = aws_dynamodb_table.chat_history.name
    region     = var.region
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
      Resource = aws_cloudformation_stack.chat_api.outputs["ApiArn"],
      Condition = {
        IpAddress = { "aws:VpcSourceIp" = var.vpc_cidr }
      }
    }]
  })
}

resource "aws_ssm_parameter" "api_url_wss" {
  name  = "/app/chat/api_url_wss"
  type  = "String"
  value = aws_cloudformation_stack.chat_api.outputs["RealTimeUrl"]
}

resource "aws_ssm_parameter" "api_url_https" {
  name  = "/app/chat/api_url_https"
  type  = "String"
  value = aws_cloudformation_stack.chat_api.outputs["GraphQLUrl"]
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

