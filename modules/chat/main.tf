data "aws_region" "current" {}

resource "aws_dynamodb_table" "messages" {
  name         = "${var.app_name}-chat-messages"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "channel"
  range_key    = "ts"

  attribute {
    name = "channel"
    type = "S"
  }

  attribute {
    name = "ts"
    type = "S"
  }
}

resource "aws_iam_role" "appsync_dynamo" {
  name = "${var.app_name}-chat-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "appsync.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "dynamo" {
  name = "${var.app_name}-chat-dynamo"
  role = aws_iam_role.appsync_dynamo.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["dynamodb:PutItem", "dynamodb:Query"]
      Resource = aws_dynamodb_table.messages.arn
    }]
  })
}

resource "aws_iam_role" "appsync_logs" {
  name = "${var.app_name}-appsync-logs"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "appsync.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "logs" {
  role       = aws_iam_role.appsync_logs.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppSyncPushToCloudWatchLogs"
}


resource "aws_appsync_graphql_api" "chat" {
  name                = "${var.app_name}-chat"
  authentication_type = "AWS_IAM"

  schema = file("${path.module}/schema.graphql")

  log_config {
    field_log_level          = "ERROR"
    cloudwatch_logs_role_arn = aws_iam_role.appsync_logs.arn
  }

  xray_enabled = true
}

resource "aws_appsync_datasource" "messages" {
  api_id           = aws_appsync_graphql_api.chat.id
  name             = "MessagesTable"
  type             = "AMAZON_DYNAMODB"
  service_role_arn = aws_iam_role.appsync_dynamo.arn

  dynamodb_config {
    table_name = aws_dynamodb_table.messages.name
    region     = data.aws_region.current.name
  }
}

resource "aws_appsync_resolver" "get_messages" {
  api_id      = aws_appsync_graphql_api.chat.id
  type        = "Query"
  field       = "getMessages"
  data_source = aws_appsync_datasource.messages.name

  request_template  = <<EOT
{"version": "2017-02-28", "operation": "Query", "query": {"expression": "channel = :c", "expressionValues": {":c": {"S": "$ctx.args.channel"}}}, "scanIndexForward": false}
EOT
  response_template = "$util.toJson($ctx.result.items)"
}

resource "aws_appsync_resolver" "send_message" {
  api_id      = aws_appsync_graphql_api.chat.id
  type        = "Mutation"
  field       = "sendMessage"
  data_source = aws_appsync_datasource.messages.name

  request_template  = <<EOT
{"version": "2017-02-28", "operation": "PutItem", "key": {"channel": {"S": "$ctx.args.channel"}, "ts": {"S": "$util.time.nowISO8601()"}}, "attributeValues": {"userId": {"S": "$ctx.args.userId"}, "content": {"S": "$ctx.args.content"}}}
EOT
  response_template = "$util.toJson($ctx.result)"
}

resource "aws_appsync_domain_name" "this" {
  count           = var.domain_name == null ? 0 : 1
  domain_name     = var.domain_name
  certificate_arn = var.certificate_arn
}

resource "aws_appsync_domain_name_api_association" "this" {
  count       = var.domain_name == null ? 0 : 1
  domain_name = aws_appsync_domain_name.this[0].domain_name
  api_id      = aws_appsync_graphql_api.chat.id
}
